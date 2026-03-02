#include "mqtt_handler.h"
#include "network_transport.h"
#include "esp_log.h"
#include "esp_tls.h"
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "esp_timer.h"

// AWS IoT SDK includes
#include "core_mqtt.h"
#include "shadow.h"

// --- Binary Embedded Certificate Symbols ---
extern const uint8_t aws_root_ca_start[] asm("_binary_root_ca_pem_start");
extern const uint8_t aws_root_ca_end[]   asm("_binary_root_ca_pem_end");

extern const uint8_t aws_device_cert_start[] asm("_binary_device_cert_crt_start");
extern const uint8_t aws_device_cert_end[]   asm("_binary_device_cert_crt_end");

extern const uint8_t aws_device_key_start[] asm("_binary_device_key_key_start");
extern const uint8_t aws_device_key_end[]   asm("_binary_device_key_key_end");

#define TAG "MQTT_AWS"
#define MQTT_BUFFER_SIZE 2048
#define OUTGOING_PUBLISH_RECORD_COUNT 10

// MQTT Context
static MQTTContext_t mqttContext;
static NetworkContext_t networkContext;
static uint8_t mqttBuffer[MQTT_BUFFER_SIZE];
static MQTTFixedBuffer_t mqttFixedBuffer = { mqttBuffer, MQTT_BUFFER_SIZE };

// QoS1/QoS2 state buffers
static MQTTPubAckInfo_t outgoingPublishRecords[OUTGOING_PUBLISH_RECORD_COUNT];
static MQTTPubAckInfo_t incomingPublishRecords[OUTGOING_PUBLISH_RECORD_COUNT];

// Connection state
static bool isConnected = false;
static SemaphoreHandle_t mqttMutex;
static TaskHandle_t mqttTaskHandle;
static uint16_t nextPacketId = 1;

// Shadow topic buffer
static char shadowUpdateTopic[128];

// Forward declaration
static esp_err_t mqtt_connect(void);

// Get current time in milliseconds (Required by coreMQTT)
static uint32_t getTime(void) {
    return (uint32_t)(esp_timer_get_time() / 1000);
}

// MQTT event callback
static void mqtt_event_callback(MQTTContext_t *pMqttContext,
                                MQTTPacketInfo_t *pPacketInfo,
                                MQTTDeserializedInfo_t *pDeserializedInfo) {
    if (pPacketInfo->type == MQTT_PACKET_TYPE_CONNACK) {
        ESP_LOGI(TAG, "Connected to AWS IoT Core");
    } else if (pPacketInfo->type == MQTT_PACKET_TYPE_DISCONNECT) {
        ESP_LOGW(TAG, "Disconnected from AWS IoT Core");
        isConnected = false;
    }
}

// Connect to AWS IoT Core
static esp_err_t mqtt_connect(void) {
    ESP_LOGI(TAG, "Connecting to AWS IoT: %s:8883", AWS_IOT_ENDPOINT);

     // DEBUG: Check certificate sizes
    // size_t root_ca_size = aws_root_ca_end - aws_root_ca_start;
    // size_t cert_size = aws_device_cert_end - aws_device_cert_start;
    // size_t key_size = aws_device_key_end - aws_device_key_start;
    
    // ESP_LOGI(TAG, "Root CA size: %d bytes", root_ca_size);
    // ESP_LOGI(TAG, "Device cert size: %d bytes", cert_size);
    // ESP_LOGI(TAG, "Device key size: %d bytes", key_size);
    
    // // Print first 50 chars of each to verify format
    // ESP_LOGI(TAG, "Root CA starts with: %.100s", (char*)aws_root_ca_start);
    // ESP_LOGI(TAG, "Device cert starts with: %.100s", (char*)aws_device_cert_start);
    // ESP_LOGI(TAG, "Device key starts with: %.100s", (char*)aws_device_key_start);
    
    // Initialize network context
    memset(&networkContext, 0, sizeof(networkContext));
    networkContext.pcHostname = AWS_IOT_ENDPOINT;
    networkContext.xPort = 8883;

    networkContext.pcServerRootCA = (const char *)aws_root_ca_start;
    networkContext.pcServerRootCASize = (aws_root_ca_end - aws_root_ca_start);

    networkContext.pcClientCert = (const char *)aws_device_cert_start;
    networkContext.pcClientCertSize = (aws_device_cert_end - aws_device_cert_start);

    networkContext.pcClientKey = (const char *)aws_device_key_start;
    networkContext.pcClientKeySize = (aws_device_key_end - aws_device_key_start);

    networkContext.pAlpnProtos = NULL;
    networkContext.disableSni = pdFALSE;
    networkContext.use_secure_element = false;
    networkContext.ds_data = NULL;
    
    // Create semaphore for network context
    networkContext.xTlsContextSemaphore = xSemaphoreCreateMutex();
    if (!networkContext.xTlsContextSemaphore) {
        ESP_LOGE(TAG, "Failed to create TLS semaphore");
        return ESP_FAIL;
    }

    // Set timeouts
    vTlsSetConnectTimeout(10000);
    vTlsSetSendTimeout(5000);
    vTlsSetRecvTimeout(5000);

    // Connect using library function
    TlsTransportStatus_t tlsStatus = xTlsConnect(&networkContext);
    if (tlsStatus != TLS_TRANSPORT_SUCCESS) {
        ESP_LOGE(TAG, "TLS connection failed: %d", tlsStatus);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }

    // Setup transport interface
    TransportInterface_t transport;
    memset(&transport, 0, sizeof(transport));
    transport.pNetworkContext = &networkContext;
    transport.send = espTlsTransportSend;  // Use library function
    transport.recv = espTlsTransportRecv;  // Use library function

    // Initialize MQTT with time function and event callback
    MQTTStatus_t mqttStatus = MQTT_Init(&mqttContext, &transport, 
                                        getTime, mqtt_event_callback, &mqttFixedBuffer);
    if (mqttStatus != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_Init failed: %d", mqttStatus);
        xTlsDisconnect(&networkContext);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }

    // Enable QoS1/QoS2 support
    mqttStatus = MQTT_InitStatefulQoS(&mqttContext, 
                                       outgoingPublishRecords, OUTGOING_PUBLISH_RECORD_COUNT,
                                       incomingPublishRecords, OUTGOING_PUBLISH_RECORD_COUNT);
    if (mqttStatus != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_InitStatefulQoS failed: %d", mqttStatus);
        xTlsDisconnect(&networkContext);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }

    // Connect to MQTT broker
    MQTTConnectInfo_t connectInfo;
    memset(&connectInfo, 0, sizeof(connectInfo));
    connectInfo.cleanSession = true;
    connectInfo.pClientIdentifier = THING_NAME;
    connectInfo.clientIdentifierLength = strlen(THING_NAME);
    connectInfo.keepAliveSeconds = 120;

    bool sessionPresent = false;
    mqttStatus = MQTT_Connect(&mqttContext, &connectInfo, NULL, 5000, &sessionPresent);
    if (mqttStatus != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_Connect failed: %d", mqttStatus);
        xTlsDisconnect(&networkContext);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }

    isConnected = true;
    ESP_LOGI(TAG, "MQTT connected successfully (session: %d)", sessionPresent);
    
    // Build shadow topic
    snprintf(shadowUpdateTopic, sizeof(shadowUpdateTopic),
             "$aws/things/%s/shadow/update", THING_NAME);
    
    return ESP_OK;
}

// MQTT processing task
static void mqtt_task(void *pvParameters) {
    while (1) {
        if (isConnected) {
            xSemaphoreTake(mqttMutex, portMAX_DELAY);
            
            MQTTStatus_t status = MQTT_ProcessLoop(&mqttContext);
            
            xSemaphoreGive(mqttMutex);
            
            if (status != MQTTSuccess && status != MQTTNeedMoreBytes) {
                ESP_LOGW(TAG, "MQTT_ProcessLoop error: %d, marking disconnected", status);
                isConnected = false;
            }
            
            vTaskDelay(pdMS_TO_TICKS(10));  // 10ms delay
        } else {
            vTaskDelay(pdMS_TO_TICKS(1000));  // 1 second when disconnected
        }
    }
}

bool mqtt_is_connected(void) {
    return isConnected;
}

esp_err_t mqtt_publish_shadow_update(const char* json_payload) {
    if (!isConnected) {
        ESP_LOGE(TAG, "Cannot publish - not connected");
        return ESP_FAIL;
    }

    xSemaphoreTake(mqttMutex, portMAX_DELAY);

    // Get next packet ID
    uint16_t packetId = nextPacketId++;
    if (nextPacketId == 0) nextPacketId = 1;  // Skip 0

    // Initialize publish info
    MQTTPublishInfo_t publishInfo;
    memset(&publishInfo, 0, sizeof(publishInfo));
    publishInfo.qos = MQTTQoS1;
    publishInfo.retain = false;
    publishInfo.dup = false;
    publishInfo.pTopicName = shadowUpdateTopic;
    publishInfo.topicNameLength = strlen(shadowUpdateTopic);
    publishInfo.pPayload = json_payload;
    publishInfo.payloadLength = strlen(json_payload);

    MQTTStatus_t status = MQTT_Publish(&mqttContext, &publishInfo, packetId);
    
    xSemaphoreGive(mqttMutex);

    if (status != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_Publish failed: %d", status);
        return ESP_FAIL;
    }

    ESP_LOGI(TAG, "Published packet ID %d: %s", packetId, json_payload);
    return ESP_OK;
}

void mqtt_app_start(void) {
    mqttMutex = xSemaphoreCreateMutex();
    
    if (mqtt_connect() == ESP_OK) {
        xTaskCreate(mqtt_task, "mqtt_task", 8192, NULL, 5, &mqttTaskHandle);
        ESP_LOGI(TAG, "AWS IoT MQTT started");
    } else {
        ESP_LOGE(TAG, "Failed to start AWS IoT MQTT");
    }
}
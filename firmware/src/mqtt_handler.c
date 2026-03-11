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

// Binary root CA embedded in firmware
extern const uint8_t aws_root_ca_start[] asm("_binary_root_ca_pem_start");
extern const uint8_t aws_root_ca_end[]   asm("_binary_root_ca_pem_end");

#define TAG "MQTT_AWS"
#define MQTT_BUFFER_SIZE 6144
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

// Subscription callbacks (max 10 subscriptions)
#define MAX_SUBSCRIPTIONS 10
typedef struct {
    char topic[128];
    mqtt_message_callback_t callback;
} subscription_t;
static subscription_t subscriptions[MAX_SUBSCRIPTIONS];
static int subscription_count = 0;

// Dynamic certificate storage (used by mqtt_connect_with_certs)
static char* dynamic_client_id = NULL;
static char* dynamic_root_ca = NULL;
static char* dynamic_device_cert = NULL;
static char* dynamic_device_key = NULL;

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
    } else if ((pPacketInfo->type & 0xF0U) == MQTT_PACKET_TYPE_PUBLISH) {
        // Handle incoming PUBLISH message
        MQTTPublishInfo_t* pPublishInfo = pDeserializedInfo->pPublishInfo;
        
        // Find matching subscription callback
        for (int i = 0; i < subscription_count; i++) {
            if (pPublishInfo->topicNameLength == strlen(subscriptions[i].topic) &&
                memcmp(pPublishInfo->pTopicName, subscriptions[i].topic, pPublishInfo->topicNameLength) == 0) {
                
                // Call the registered callback
                if (subscriptions[i].callback != NULL) {
                    subscriptions[i].callback(
                        subscriptions[i].topic,
                        (const char*)pPublishInfo->pPayload,
                        pPublishInfo->payloadLength
                    );
                }
                break;
            }
        }
    }
}

// Connect to AWS IoT Core
static esp_err_t mqtt_connect(void) {
    ESP_LOGI(TAG, "Connecting to AWS IoT: %s:8883", AWS_IOT_ENDPOINT);

     // Initialize network context
    memset(&networkContext, 0, sizeof(networkContext));
    networkContext.pcHostname = AWS_IOT_ENDPOINT;
    networkContext.xPort = 8883;

    networkContext.pcServerRootCA = (const char *)aws_root_ca_start;
    networkContext.pcServerRootCASize = (aws_root_ca_end - aws_root_ca_start);

    // Device certs come from dynamic provisioning, not embedded files
    networkContext.pcClientCert = NULL;
    networkContext.pcClientCertSize = 0;

    networkContext.pcClientKey = NULL;
    networkContext.pcClientKeySize = 0;

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

    // Set timeouts (shorter recv timeout prevents blocking MQTT_ProcessLoop)
    vTlsSetConnectTimeout(10000);
    vTlsSetSendTimeout(5000);
    vTlsSetRecvTimeout(2000);  // 2s recv timeout

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
            // Re-check under mutex to prevent TOCTOU race with mqtt_disconnect
            if (isConnected) {
                MQTTStatus_t status = MQTT_ProcessLoop(&mqttContext);
                if (status != MQTTSuccess && status != MQTTNeedMoreBytes) {
                    ESP_LOGW(TAG, "MQTT_ProcessLoop error: %d, marking disconnected", status);
                    isConnected = false;
                }
            }
            xSemaphoreGive(mqttMutex);
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
        xTaskCreate(mqtt_task, "mqtt_task", 8192, NULL, 7, &mqttTaskHandle);
        ESP_LOGI(TAG, "AWS IoT MQTT started");
    } else {
        ESP_LOGE(TAG, "Failed to start AWS IoT MQTT");
    }
}

// Fleet Provisioning - Connect with dynamic certificates
esp_err_t mqtt_connect_with_certs(const char* client_id, const char* root_ca,
                                   const char* device_cert, const char* device_key) {
    ESP_LOGI(TAG, "Connecting to AWS IoT with dynamic certs: %s:8883", AWS_IOT_ENDPOINT);
    ESP_LOGI(TAG, "Client ID: %s", client_id);
    
    // Store dynamic certs (freed on disconnect)
    if (dynamic_client_id) free(dynamic_client_id);
    if (dynamic_root_ca) free(dynamic_root_ca);
    if (dynamic_device_cert) free(dynamic_device_cert);
    if (dynamic_device_key) free(dynamic_device_key);
    
    dynamic_client_id = strdup(client_id);
    dynamic_root_ca = strdup(root_ca);
    dynamic_device_cert = strdup(device_cert);
    dynamic_device_key = strdup(device_key);
    
    if (!dynamic_client_id || !dynamic_root_ca || !dynamic_device_cert || !dynamic_device_key) {
        ESP_LOGE(TAG, "Failed to allocate memory for certificates");
        return ESP_ERR_NO_MEM;
    }
    
    // Initialize network context with dynamic certs
    // memset zeros out any old semaphore handle, so we start fresh
    memset(&networkContext, 0, sizeof(networkContext));
    networkContext.pcHostname = AWS_IOT_ENDPOINT;
    networkContext.xPort = 8883;
    
    networkContext.pcServerRootCA = dynamic_root_ca;
    networkContext.pcServerRootCASize = strlen(dynamic_root_ca) + 1;
    
    networkContext.pcClientCert = dynamic_device_cert;
    networkContext.pcClientCertSize = strlen(dynamic_device_cert) + 1;
    
    networkContext.pcClientKey = dynamic_device_key;
    networkContext.pcClientKeySize = strlen(dynamic_device_key) + 1;
    
    networkContext.pAlpnProtos = NULL;
    networkContext.disableSni = pdFALSE;
    networkContext.use_secure_element = false;
    networkContext.ds_data = NULL;
    
    // Create semaphore
    networkContext.xTlsContextSemaphore = xSemaphoreCreateMutex();
    if (!networkContext.xTlsContextSemaphore) {
        ESP_LOGE(TAG, "Failed to create TLS semaphore");
        return ESP_FAIL;
    }
    
    // Set timeouts (shorter recv timeout prevents blocking MQTT_ProcessLoop)
    vTlsSetConnectTimeout(10000);
    vTlsSetSendTimeout(5000);
    vTlsSetRecvTimeout(2000);  // 2s recv timeout
    
    // Connect TLS (expensive ECDH operations, timeout is 60 seconds which is sufficient)
    TlsTransportStatus_t tlsStatus = xTlsConnect(&networkContext);
    if (tlsStatus != TLS_TRANSPORT_SUCCESS) {
        ESP_LOGE(TAG, "TLS connection failed: %d", tlsStatus);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }
    
    // Setup transport
    TransportInterface_t transport;
    memset(&transport, 0, sizeof(transport));
    transport.pNetworkContext = &networkContext;
    transport.send = espTlsTransportSend;
    transport.recv = espTlsTransportRecv;
    
    // Create mutex if not already exists (needed before context reinitialization)
    if (mqttMutex == NULL) {
        mqttMutex = xSemaphoreCreateMutex();
    }
    
    // Hold mutex while reinitializing context to prevent mqtt_task from using corrupted state
    xSemaphoreTake(mqttMutex, portMAX_DELAY);
    
    // Initialize MQTT
    MQTTStatus_t mqttStatus = MQTT_Init(&mqttContext, &transport,
                                        getTime, mqtt_event_callback, &mqttFixedBuffer);
    if (mqttStatus != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_Init failed: %d", mqttStatus);
        xSemaphoreGive(mqttMutex);
        xTlsDisconnect(&networkContext);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }
    
    // Enable QoS support
    mqttStatus = MQTT_InitStatefulQoS(&mqttContext,
                                       outgoingPublishRecords, OUTGOING_PUBLISH_RECORD_COUNT,
                                       incomingPublishRecords, OUTGOING_PUBLISH_RECORD_COUNT);
    if (mqttStatus != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_InitStatefulQoS failed: %d", mqttStatus);
        xSemaphoreGive(mqttMutex);
        xTlsDisconnect(&networkContext);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }
    
    // Connect to MQTT broker with dynamic client ID
    MQTTConnectInfo_t connectInfo;
    memset(&connectInfo, 0, sizeof(connectInfo));
    connectInfo.cleanSession = true;
    connectInfo.pClientIdentifier = dynamic_client_id;
    connectInfo.clientIdentifierLength = strlen(dynamic_client_id);
    connectInfo.keepAliveSeconds = 120;
    
    bool sessionPresent = false;
    mqttStatus = MQTT_Connect(&mqttContext, &connectInfo, NULL, 5000, &sessionPresent);
    if (mqttStatus != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_Connect failed: %d", mqttStatus);
        xSemaphoreGive(mqttMutex);
        xTlsDisconnect(&networkContext);
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        return ESP_FAIL;
    }
    
    isConnected = true;
    xSemaphoreGive(mqttMutex);  // Release mutex after context is stable
    
    ESP_LOGI(TAG, "MQTT connected successfully as '%s' (session: %d)", dynamic_client_id, sessionPresent);
    
    // Start MQTT task if not already running
    if (mqttTaskHandle == NULL) {
        xTaskCreate(mqtt_task, "mqtt_task", 8192, NULL, 7, &mqttTaskHandle);
    }
    
    return ESP_OK;
}

// Subscribe to MQTT topic with callback
esp_err_t mqtt_subscribe(const char* topic, mqtt_message_callback_t callback) {
    if (!isConnected) {
        ESP_LOGE(TAG, "Cannot subscribe - not connected");
        return ESP_FAIL;
    }
    
    if (subscription_count >= MAX_SUBSCRIPTIONS) {
        ESP_LOGE(TAG, "Maximum subscriptions reached");
        return ESP_FAIL;
    }
    
    ESP_LOGI(TAG, "Subscribing to: %s", topic);
    
    xSemaphoreTake(mqttMutex, portMAX_DELAY);
    
    // Subscribe using MQTT library
    MQTTSubscribeInfo_t subscribeInfo;
    subscribeInfo.qos = MQTTQoS1;
    subscribeInfo.pTopicFilter = topic;
    subscribeInfo.topicFilterLength = strlen(topic);
    
    uint16_t packetId = nextPacketId++;
    if (nextPacketId == 0) nextPacketId = 1;
    
    MQTTStatus_t status = MQTT_Subscribe(&mqttContext, &subscribeInfo, 1, packetId);
    
    xSemaphoreGive(mqttMutex);
    
    if (status != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_Subscribe failed: %d", status);
        return ESP_FAIL;
    }
    
    // Store subscription callback
    strncpy(subscriptions[subscription_count].topic, topic, sizeof(subscriptions[subscription_count].topic) - 1);
    subscriptions[subscription_count].callback = callback;
    subscription_count++;
    
    ESP_LOGI(TAG, "Subscribed to %s (packet ID %d)", topic, packetId);
    return ESP_OK;
}

// Generic MQTT publish
esp_err_t mqtt_publish(const char* topic, const char* payload, size_t len) {
    if (!isConnected) {
        ESP_LOGE(TAG, "Cannot publish - not connected");
        return ESP_FAIL;
    }
    
    xSemaphoreTake(mqttMutex, portMAX_DELAY);
    
    uint16_t packetId = nextPacketId++;
    if (nextPacketId == 0) nextPacketId = 1;
    
    MQTTPublishInfo_t publishInfo;
    memset(&publishInfo, 0, sizeof(publishInfo));
    publishInfo.qos = MQTTQoS1;
    publishInfo.retain = false;
    publishInfo.dup = false;
    publishInfo.pTopicName = topic;
    publishInfo.topicNameLength = strlen(topic);
    publishInfo.pPayload = payload;
    publishInfo.payloadLength = len;
    
    MQTTStatus_t status = MQTT_Publish(&mqttContext, &publishInfo, packetId);
    
    xSemaphoreGive(mqttMutex);
    
    if (status != MQTTSuccess) {
        ESP_LOGE(TAG, "MQTT_Publish failed: %d", status);
        return ESP_FAIL;
    }
    
    ESP_LOGI(TAG, "Published to %s (packet ID %d, %d bytes)", topic, packetId, len);
    return ESP_OK;
}

// Disconnect from MQTT broker
esp_err_t mqtt_disconnect(void) {
    if (!isConnected) {
        ESP_LOGW(TAG, "Already disconnected");
        return ESP_OK;
    }
    
    ESP_LOGI(TAG, "Disconnecting from MQTT...");
    
    xSemaphoreTake(mqttMutex, portMAX_DELAY);
    
    // Send MQTT DISCONNECT
    MQTTStatus_t status = MQTT_Disconnect(&mqttContext);
    if (status != MQTTSuccess) {
        ESP_LOGW(TAG, "MQTT_Disconnect returned: %d", status);
    }
    
    // Disconnect TLS
    xTlsDisconnect(&networkContext);
    
    // Clean up semaphore
    if (networkContext.xTlsContextSemaphore) {
        vSemaphoreDelete(networkContext.xTlsContextSemaphore);
        networkContext.xTlsContextSemaphore = NULL;
    }
    
    isConnected = false;
    subscription_count = 0;  // Clear subscriptions
    
    xSemaphoreGive(mqttMutex);
    
    // Free dynamic certificates
    if (dynamic_client_id) {
        free(dynamic_client_id);
        dynamic_client_id = NULL;
    }
    if (dynamic_root_ca) {
        free(dynamic_root_ca);
        dynamic_root_ca = NULL;
    }
    if (dynamic_device_cert) {
        free(dynamic_device_cert);
        dynamic_device_cert = NULL;
    }
    if (dynamic_device_key) {
        free(dynamic_device_key);
        dynamic_device_key = NULL;
    }
    
    ESP_LOGI(TAG, "Disconnected successfully");
    return ESP_OK;
}
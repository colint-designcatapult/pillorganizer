#include "mqtt_wrapper.h"
#include "mqtt_client.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include <string.h>

#define TAG "MQTT_WRAPPER"

#define TEMPLATE_NAME "TenantDeviceProvisioningTemplate"
#define MQTT_HOST "mqtt.app.healthesolutions.ca"
#define MQTT_PORT 8883


// Global state
static esp_mqtt_client_handle_t mqtt_client = NULL;
static EventGroupHandle_t mqtt_event_group = NULL;
static esp_event_handler_t app_data_callback = NULL;

extern const uint8_t aws_root_ca_start[] asm("_binary_root_ca_pem_start");
extern const uint8_t aws_root_ca_end[] asm("_binary_root_ca_pem_end");

// Event bits for synchronization
#define MQTT_CONNECTED_BIT      (1 << 0)
#define MQTT_DISCONNECTED_BIT   (1 << 1)

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;

    switch ((esp_mqtt_event_id_t)event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT Connected");
            xEventGroupClearBits(mqtt_event_group, MQTT_DISCONNECTED_BIT);
            xEventGroupSetBits(mqtt_event_group, MQTT_CONNECTED_BIT);
            break;

        case MQTT_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "MQTT Disconnected");
            xEventGroupClearBits(mqtt_event_group, MQTT_CONNECTED_BIT);
            xEventGroupSetBits(mqtt_event_group, MQTT_DISCONNECTED_BIT);
            break;
        default:
            break;
    }
    if (app_data_callback != NULL) {
        app_data_callback(handler_args, base, event_id, event_data);
    }
}

esp_err_t mqtt_wrapper_connect(const mqtt_wrapper_config_t* config) {
    if (mqtt_client != NULL) {
        ESP_LOGE(TAG, "Client already initialized. Call disconnect first.");
        return ESP_ERR_INVALID_STATE;
    }

    if (mqtt_event_group == NULL) {
        mqtt_event_group = xEventGroupCreate();
    }

    const char* root_ca = (const char*)aws_root_ca_start;
    const int root_ca_len = (int)(aws_root_ca_end - aws_root_ca_start);

    // ESP-IDF v5.x Configuration Structure
    esp_mqtt_client_config_t mqtt_cfg = {
        .broker = {
            .address = {
                .hostname = MQTT_HOST,
                .transport = MQTT_TRANSPORT_OVER_SSL,
                .port = MQTT_PORT
            },
            .verification = {
                .certificate = root_ca,
                .certificate_len = root_ca_len
            }
        },
        .credentials = {
            .client_id = config->client_id,
            .authentication = {
                .certificate = config->client_cert_pem,
                .key = config->client_key_pem
            }
        },
        .buffer = {
            .size = 4096,
            .out_size = 4096
        }
    };

    mqtt_client = esp_mqtt_client_init(&mqtt_cfg);
    if (!mqtt_client) return ESP_FAIL;

    app_data_callback = config->event_handler;    

    esp_err_t err = esp_mqtt_client_register_event(mqtt_client,
             (esp_mqtt_event_id_t)ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    if(err != ESP_OK) return err;
    return esp_mqtt_client_start(mqtt_client);
}

esp_err_t mqtt_wrapper_disconnect(void) {
    if (mqtt_client == NULL) return ESP_OK; // Already disconnected

    esp_mqtt_client_stop(mqtt_client);
    esp_mqtt_client_destroy(mqtt_client);
    mqtt_client = NULL;
    app_data_callback = NULL;

    ESP_LOGI(TAG, "MQTT Client Destroyed");
    return ESP_OK;
}

esp_err_t mqtt_wrapper_publish(const char* topic, const char* payload, int len, int qos) {
    if (!mqtt_wrapper_is_connected()) return ESP_ERR_INVALID_STATE;
    
    int msg_id = esp_mqtt_client_publish(mqtt_client, topic, payload, len, qos, 0);
    return (msg_id >= 0) ? ESP_OK : ESP_FAIL;
}

esp_err_t mqtt_wrapper_subscribe(const char* topic, int qos) {
    if (!mqtt_wrapper_is_connected()) return ESP_ERR_INVALID_STATE;

    int msg_id = esp_mqtt_client_subscribe(mqtt_client, topic, qos);
    return (msg_id >= 0) ? ESP_OK : ESP_FAIL;
}

bool mqtt_wrapper_is_connected(void) {
    if (mqtt_event_group == NULL) return false;
    EventBits_t bits = xEventGroupGetBits(mqtt_event_group);
    return (bits & MQTT_CONNECTED_BIT) != 0;
}
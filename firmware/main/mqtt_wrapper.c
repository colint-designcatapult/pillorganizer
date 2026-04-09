#include "mqtt_wrapper.h"
#include "mqtt_client.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/semphr.h"
#include <string.h>
#include "supervisor.h"

#define TAG "MQTT_WRAPPER"

#define TEMPLATE_NAME "TenantDeviceProvisioningTemplate"
#define MQTT_HOST "mqtt.app.healthesolutions.ca"
#define MQTT_PORT 8883


// Global state
static esp_mqtt_client_handle_t mqtt_client = NULL;
static EventGroupHandle_t mqtt_event_group = NULL;
static esp_event_handler_t app_data_callback = NULL;

/* Mutex protecting mqtt_client handle reads and writes.
 * The handle is copied under the mutex and then used outside it so we never
 * hold the lock across a blocking MQTT API call. */
static SemaphoreHandle_t s_client_mutex = NULL;

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
            supervisor_submit_event(EVENT_MQTT_CONNECTED);
            break;

        case MQTT_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "MQTT Disconnected");
            xEventGroupClearBits(mqtt_event_group, MQTT_CONNECTED_BIT);
            xEventGroupSetBits(mqtt_event_group, MQTT_DISCONNECTED_BIT);
            supervisor_submit_event(EVENT_MQTT_DISCONNECTED);
            break;
        default:
            break;
    }
    if (app_data_callback != NULL) {
        app_data_callback(handler_args, base, event_id, event_data);
    }
}

void mqtt_wrapper_init(void)
{
    if (s_client_mutex == NULL) {
        s_client_mutex = xSemaphoreCreateMutex();
        configASSERT(s_client_mutex != NULL);
    }
}

esp_err_t mqtt_wrapper_connect(const mqtt_wrapper_config_t* config) {
    /* Lazily initialise the module so call sites that do not call
     * mqtt_wrapper_init() explicitly (e.g., fleet provisioning) still work. */
    mqtt_wrapper_init();

    xSemaphoreTake(s_client_mutex, portMAX_DELAY);
    bool already_init = (mqtt_client != NULL);
    xSemaphoreGive(s_client_mutex);

    if (already_init) {
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

    esp_mqtt_client_handle_t new_client = esp_mqtt_client_init(&mqtt_cfg);
    if (!new_client) return ESP_FAIL;

    esp_err_t err = esp_mqtt_client_register_event(new_client,
             (esp_mqtt_event_id_t)ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    if (err != ESP_OK) {
        esp_mqtt_client_destroy(new_client);
        return err;
    }

    err = esp_mqtt_client_start(new_client);
    if (err != ESP_OK) {
        if (mqtt_event_group != NULL) {
            xEventGroupClearBits(mqtt_event_group, MQTT_CONNECTED_BIT);
            xEventGroupSetBits(mqtt_event_group, MQTT_DISCONNECTED_BIT);
        }
        app_data_callback = NULL;
        esp_mqtt_client_destroy(new_client);
        return err;
    }

    app_data_callback = config->event_handler;

    /* Publish the handle only after it is fully configured and started. */
    xSemaphoreTake(s_client_mutex, portMAX_DELAY);
    mqtt_client = new_client;
    xSemaphoreGive(s_client_mutex);

    return ESP_OK;
}

esp_err_t mqtt_wrapper_disconnect(void) {
    if (s_client_mutex == NULL) return ESP_OK; // Never connected

    /* Atomically take and null the handle so publish/subscribe callers that
     * snapshot it under the mutex cannot reach a destroyed object. */
    xSemaphoreTake(s_client_mutex, portMAX_DELAY);
    esp_mqtt_client_handle_t old_client = mqtt_client;
    mqtt_client = NULL;
    xSemaphoreGive(s_client_mutex);

    if (old_client == NULL) return ESP_OK; // Already disconnected

    /* Clear the connected bit so is_connected() returns false immediately. */
    if (mqtt_event_group != NULL) {
        xEventGroupClearBits(mqtt_event_group, MQTT_CONNECTED_BIT);
        xEventGroupSetBits(mqtt_event_group, MQTT_DISCONNECTED_BIT);
    }

    esp_mqtt_client_stop(old_client);
    esp_mqtt_client_destroy(old_client);
    app_data_callback = NULL;

    ESP_LOGI(TAG, "MQTT Client Destroyed");
    return ESP_OK;
}

esp_err_t mqtt_wrapper_publish_with_id(const char* topic, const char* payload, int len, int qos, int retain, int* out_msg_id) {
    if (!mqtt_wrapper_is_connected()) return ESP_ERR_INVALID_STATE;

    /* Guard against calls made before mqtt_wrapper_init(). */
    if (s_client_mutex == NULL) return ESP_ERR_INVALID_STATE;

    /* Snapshot the handle under the mutex to close the TOCTOU window between
     * the is_connected() check and the actual publish call. */
    xSemaphoreTake(s_client_mutex, portMAX_DELAY);
    esp_mqtt_client_handle_t client = mqtt_client;
    xSemaphoreGive(s_client_mutex);
    if (client == NULL) return ESP_ERR_INVALID_STATE;

    int msg_id = esp_mqtt_client_publish(client, topic, payload, len, qos, retain);
    if (msg_id < 0) return ESP_FAIL;

    if (out_msg_id != NULL) {
        *out_msg_id = msg_id;
    }
    return ESP_OK;
}

esp_err_t mqtt_wrapper_publish(const char* topic, const char* payload, int len, int qos, int retain) {
    if (!mqtt_wrapper_is_connected()) return ESP_ERR_INVALID_STATE;

    /* Guard against calls made before mqtt_wrapper_init(). */
    if (s_client_mutex == NULL) return ESP_ERR_INVALID_STATE;

    xSemaphoreTake(s_client_mutex, portMAX_DELAY);
    esp_mqtt_client_handle_t client = mqtt_client;
    xSemaphoreGive(s_client_mutex);
    if (client == NULL) return ESP_ERR_INVALID_STATE;

    int msg_id = esp_mqtt_client_publish(client, topic, payload, len, qos, retain);
    return (msg_id >= 0) ? ESP_OK : ESP_FAIL;
}

esp_err_t mqtt_wrapper_subscribe(const char* topic, int qos, int* out_id)
{
    if (out_id != NULL) {
        *out_id = 0;
    }

    if (!mqtt_wrapper_is_connected()) return ESP_ERR_INVALID_STATE;

    /* Guard against calls made before mqtt_wrapper_init(). */
    if (s_client_mutex == NULL) return ESP_ERR_INVALID_STATE;

    xSemaphoreTake(s_client_mutex, portMAX_DELAY);
    esp_mqtt_client_handle_t client = mqtt_client;
    xSemaphoreGive(s_client_mutex);
    if (client == NULL) return ESP_ERR_INVALID_STATE;

    int msg_id = esp_mqtt_client_subscribe(client, topic, qos);
    if (out_id != NULL && msg_id >= 0) {
        *out_id = msg_id;
    }
    return (msg_id >= 0) ? ESP_OK : ESP_FAIL;
}

bool mqtt_wrapper_is_connected(void) {
    if (mqtt_event_group == NULL) return false;
    EventBits_t bits = xEventGroupGetBits(mqtt_event_group);
    return (bits & MQTT_CONNECTED_BIT) != 0;
}
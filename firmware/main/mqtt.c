#include "mqtt.h"
#include "mqtt_wrapper.h"
#include "device_config.h"
#include "shadow_state.h"
#include "rtc.h"
#include <esp_log.h>
#include <mqtt_client.h>
#include <cJSON.h>


#define TAG "MQTT"

static const char* s_cert_pem = NULL;
static const char* s_key_pem = NULL;

static void cleanup_certs()
{
    if (s_cert_pem) free((void*)s_cert_pem);
    if (s_key_pem) free((void*)s_key_pem);
    s_cert_pem = NULL;
    s_key_pem = NULL;
}

esp_err_t mqtt_subscribe(const char* topic, int qos, int* out_id)
{
    return mqtt_wrapper_subscribe(topic, qos, out_id);
}

esp_err_t mqtt_publish(const char* topic, const char* payload, int len, int qos, int retain)
{
    return mqtt_wrapper_publish(topic, payload, len, qos, retain);
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;

    switch (event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT Connected");
            break;
        case MQTT_EVENT_DATA:
            shadow_state_on_data(event->topic, event->topic_len, event->data, event->data_len);
            break;
        case MQTT_EVENT_SUBSCRIBED:
            ESP_LOGI(TAG, "MQTT Subscribed to msg_id %d", event->msg_id);
            shadow_state_on_subscribe(event->msg_id);
            break;
        case MQTT_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "MQTT Disconnected");
            break;
        default:
            break;
    }
    return;
}

esp_err_t mqtt_init()
{
    // Sanity check: device must have a permanent identity
    if (!devcfg_has_permanent_identity()) {
        ESP_LOGE(TAG, "MQTT needs permanent identity");
        return ESP_ERR_INVALID_STATE;
    }

    // Get thing name
    char thing_name[128];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name");
        return ESP_ERR_INVALID_STATE;
    }

    s_cert_pem = devcfg_get_permanent_cert();
    s_key_pem = devcfg_get_permanent_key();

    mqtt_wrapper_config_t mqtt_cfg = {
        // Must connect with thing name
        .client_id = thing_name,    
        // Use permanent certs
        .client_cert_pem = s_cert_pem,
        .client_key_pem = s_key_pem,
        .event_handler = mqtt_event_handler
    };

    ESP_LOGI(TAG, "Connecting to MQTT with client ID %s", thing_name);
    
    esp_err_t err = mqtt_wrapper_connect(&mqtt_cfg);
    if (err != ESP_OK) {
        cleanup_certs();
    }
    return err;
}

esp_err_t mqtt_publish_device_state(device_state_t* state)
{
    char thing_name[128];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name");
        return ESP_ERR_INVALID_STATE;
    }

    char topic[256];
    snprintf(topic, sizeof(topic), "healthe/things/%s/state", thing_name);
    ESP_LOGI(TAG, "Publishing state to %s", topic);

    cJSON *root = cJSON_CreateObject();
    if (!root) return ESP_ERR_NO_MEM;

    uint64_t ts_ms = (uint64_t)state->modified_at;
    cJSON_AddNumberToObject(root, "timestamp", (double)ts_ms);
    cJSON_AddNumberToObject(root, "battery", state->battery);
    cJSON_AddBoolToObject(root, "charging", state->charging);
    cJSON_AddBoolToObject(root, "reloading", state->reload_state.stage != RELOAD_NONE); 
    cJSON_AddNumberToObject(root, "doors", state->doors);

    cJSON *bins_array = cJSON_AddArrayToObject(root, "bins");
    for (int i = 0; i < 14; i++) {
        cJSON *bin_obj = cJSON_CreateObject();
        cJSON_AddNumberToObject(bin_obj, "id", i);
        
        const char *status_str = "DISABLED";
        switch(state->bins[i].status) {
            case TAKEN: status_str = "TAKEN"; break;
            case MISSED: status_str = "MISSED"; break;
            case PENDING: status_str = "PENDING"; break;
            case TAKE_NOW: status_str = "TAKE_NOW"; break;
            case DISABLED: default: break;
        }
        cJSON_AddStringToObject(bin_obj, "status", status_str);
        
        if (state->bins[i].scheduled_time > 0) {
            cJSON_AddNumberToObject(bin_obj, "scheduled_time", (double)state->bins[i].scheduled_time);
        }
        if (state->bins[i].event_time > 0) {
            cJSON_AddNumberToObject(bin_obj, "event_time", (double)state->bins[i].event_time);
        }
        
        cJSON_AddItemToArray(bins_array, bin_obj);
    }

    char *json_str = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);

    if (!json_str) return ESP_ERR_NO_MEM;

    ESP_LOGI(TAG, "Publishing state: %s", json_str);
    // QoS 1, Retain 1 according to IC-3
    esp_err_t err = mqtt_publish(topic, json_str, strlen(json_str), 1, 1);
    
    free(json_str);
    return err;
}
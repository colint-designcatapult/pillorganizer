#include "mqtt.h"
#include "mqtt_wrapper.h"
#include "device_config.h"
#include "shadow_state.h"
#include "ota.h"
#include "rtc.h"
#include "event_outbox.h"
#include <esp_log.h>
#include <esp_app_desc.h>
#include <inttypes.h>
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

esp_err_t mqtt_publish_with_id(const char* topic, const char* payload, int len, int qos, int retain, int* out_msg_id)
{
    return mqtt_wrapper_publish_with_id(topic, payload, len, qos, retain, out_msg_id);
}

static const char* event_type_to_str(device_event_type_t evt)
{
    switch (evt) {
        case DEVEVT_DOOR_OPENED:    return "DOOR_OPENED";
        case DEVEVT_DOOR_CLOSED:    return "DOOR_CLOSED";
        case DEVEVT_DOOR_LEFT_OPEN: return "DOOR_LEFT_OPEN";
        case DEVEVT_TAKEN:          return "TAKEN";
        case DEVEVT_MISSED:         return "MISSED";
        case DEVEVT_TAKE_NOW:       return "TAKE_NOW";
        case DEVEVT_RELOAD_START:   return "RELOAD_START";
        case DEVEVT_RELOAD_END:     return "RELOAD_END";
        case DEVEVT_ACTION_TIMEOUT: return "RELOAD_TIMEOUT";
        case DEVEVT_ERROR:          return "ERROR";
        case DEVEVT_BIN_RESET:      return "BIN_RESET";
        default:                    return "UNKNOWN";
    }
}

esp_err_t mqtt_publish_event(const event_outbox_entry_t* entry,
                              const device_persistent_state_t* dev_state_hint,
                              int* out_msg_id)
{
    if (!mqtt_wrapper_is_connected()) {
        return ESP_ERR_INVALID_STATE;
    }

    char thing_name[128];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name for event publish");
        return ESP_ERR_INVALID_STATE;
    }

    char topic[256];
    snprintf(topic, sizeof(topic), "healthe/things/%s/event", thing_name);

    /* Use the caller-supplied device state if available to avoid an NVS
     * read per entry when draining a batch of events. */
    device_persistent_state_t dev_state_local;
    const device_persistent_state_t *dev_state = dev_state_hint;
    if (dev_state == NULL) {
        bool loaded = (devcfg_get_device_state(&dev_state_local) == ESP_OK);
        dev_state = loaded ? &dev_state_local : NULL;
    }

    cJSON *root = cJSON_CreateObject();
    if (!root) return ESP_ERR_NO_MEM;

    cJSON_AddNumberToObject(root, "timestamp",  (double)entry->event.timestamp);
    cJSON_AddStringToObject(root, "event_type", event_type_to_str(entry->event.event_type));
    if (entry->event.bin_id != DEVICE_EVENT_BIN_ID_NONE) {
        cJSON_AddNumberToObject(root, "bin_id", entry->event.bin_id);
        if (dev_state != NULL &&
            entry->event.bin_id < DEVICE_NUM_BINS &&
            dev_state->bins[entry->event.bin_id].schedule_id[0] != '\0') {
            cJSON_AddStringToObject(root, "schedule_id",
                                    dev_state->bins[entry->event.bin_id].schedule_id);
        }
    }
    if (entry->event.epoch_week != DEVICE_EVENT_EPOCH_WEEK_NONE) {
        cJSON_AddNumberToObject(root, "epoch_week", (double)entry->event.epoch_week);
    }
    if (entry->event.scheduled_time != DEVICE_EVENT_SCHEDULED_TIME_NONE) {
        cJSON_AddNumberToObject(root, "scheduled_time", (double)entry->event.scheduled_time);
    }
    if (entry->event.flags != 0) {
        cJSON_AddNumberToObject(root, "flags", entry->event.flags);
    }

    char *json_str = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    if (!json_str) return ESP_ERR_NO_MEM;

    int msg_id = -1;
    esp_err_t err = mqtt_wrapper_publish_with_id(topic, json_str,
                                                  strlen(json_str),
                                                  /*qos=*/1, /*retain=*/0,
                                                  &msg_id);
    free(json_str);

    if (err != ESP_OK || msg_id < 0) {
        ESP_LOGW(TAG, "Event publish failed for seq=%" PRIu32 " (%s)",
                 entry->seq, esp_err_to_name(err));
        return (err != ESP_OK) ? err : ESP_FAIL;
    }

    ESP_LOGI(TAG, "Event published seq=%" PRIu32 " msg_id=%d type=%s",
             entry->seq, msg_id, event_type_to_str(entry->event.event_type));
    *out_msg_id = msg_id;
    return ESP_OK;
}

static void mqtt_subscribe_command_topics(void)
{
    char thing_name[128];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not get thing name for command subscription");
        return;
    }

    char topic[256];
    esp_err_t err;

    snprintf(topic, sizeof(topic), "healthe/things/%s/cmd/reload", thing_name);
    err = mqtt_subscribe(topic, 1, NULL);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "Failed to subscribe to command topic %s: %s", topic, esp_err_to_name(err));
    } else {
        ESP_LOGI(TAG, "Subscribed to command topic: %s", topic);
    }

    snprintf(topic, sizeof(topic), "healthe/things/%s/cmd/bin", thing_name);
    err = mqtt_subscribe(topic, 1, NULL);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "Failed to subscribe to command topic %s: %s", topic, esp_err_to_name(err));
    } else {
        ESP_LOGI(TAG, "Subscribed to command topic: %s", topic);
    }
}

static void mqtt_cmd_on_data(const char* topic, size_t topic_len, const char* data, size_t data_len)
{
    /* Check if this is a command topic */
    const char* cmd_segment = "/cmd/";
    const char* found = NULL;
    for (size_t i = 0; i + 5 <= topic_len; i++) {
        if (memcmp(topic + i, cmd_segment, 5) == 0) {
            found = topic + i + 5;
            break;
        }
    }
    if (!found) return;

    size_t remaining = topic_len - (found - topic);

    /* Parse JSON payload */
    cJSON *root = cJSON_ParseWithLength(data, data_len);
    if (!root) {
        ESP_LOGW(TAG, "Failed to parse command JSON");
        return;
    }

    if (remaining >= 6 && memcmp(found, "reload", 6) == 0) {
        /* Reload command: {"reload": "INITIATE"} or {"reload": "COMPLETE"} */
        cJSON *reload_val = cJSON_GetObjectItem(root, "reload");
        if (reload_val && cJSON_IsString(reload_val)) {
            esp_err_t err;
            if (strcmp(reload_val->valuestring, "INITIATE") == 0) {
                ESP_LOGI(TAG, "Command received: RELOAD INITIATE");
                err = supervisor_submit_event_block(EVENT_CMD_RELOAD, (intptr_t)CMD_RELOAD_INITIATE, 0);
                if (err != ESP_OK) {
                    ESP_LOGW(TAG, "Failed to submit RELOAD INITIATE command (queue full)");
                }
            } else if (strcmp(reload_val->valuestring, "COMPLETE") == 0) {
                ESP_LOGI(TAG, "Command received: RELOAD COMPLETE");
                err = supervisor_submit_event_block(EVENT_CMD_RELOAD, (intptr_t)CMD_RELOAD_COMPLETE, 0);
                if (err != ESP_OK) {
                    ESP_LOGW(TAG, "Failed to submit RELOAD COMPLETE command (queue full)");
                }
            }
        }
    } else if (remaining >= 3 && memcmp(found, "bin", 3) == 0) {
        /* Bin command: {"bin": <id>, "type": "TAKEN"|"RESET"} */
        cJSON *bin_val = cJSON_GetObjectItem(root, "bin");
        cJSON *type_val = cJSON_GetObjectItem(root, "type");
        if (bin_val && cJSON_IsNumber(bin_val) && type_val && cJSON_IsString(type_val)) {
            int bin_id = bin_val->valueint;
            esp_err_t err;
            if (strcmp(type_val->valuestring, "TAKEN") == 0) {
                ESP_LOGI(TAG, "Command received: BIN TAKEN bin=%d", bin_id);
                err = supervisor_submit_event_block(EVENT_CMD_BIN_TAKEN, (intptr_t)bin_id, 0);
                if (err != ESP_OK) {
                    ESP_LOGW(TAG, "Failed to submit BIN TAKEN command for bin %d (queue full)", bin_id);
                }
            } else if (strcmp(type_val->valuestring, "RESET") == 0) {
                ESP_LOGI(TAG, "Command received: BIN RESET bin=%d", bin_id);
                err = supervisor_submit_event_block(EVENT_CMD_BIN_RESET, (intptr_t)bin_id, 0);
                if (err != ESP_OK) {
                    ESP_LOGW(TAG, "Failed to submit BIN RESET command for bin %d (queue full)", bin_id);
                }
            }
        }
    }

    cJSON_Delete(root);
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;

    switch (event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT Connected");
            mqtt_subscribe_command_topics();
            break;
        case MQTT_EVENT_DATA:
            shadow_state_on_data(event->topic, event->topic_len, event->data, event->data_len);
            ota_on_data(event->topic, event->topic_len, event->data, event->data_len);
            mqtt_cmd_on_data(event->topic, event->topic_len, event->data, event->data_len);
            break;
        case MQTT_EVENT_SUBSCRIBED:
            ESP_LOGI(TAG, "MQTT Subscribed to msg_id %d", event->msg_id);
            shadow_state_on_subscribe(event->msg_id);
            ota_on_subscribe(event->msg_id);
            break;
        case MQTT_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "MQTT Disconnected");
            break;
        case MQTT_EVENT_PUBLISHED:
            /* Marshal the PUBACK to the supervisor event loop so the outbox
             * can be acknowledged and drained without any cross-task calls.
             * A 50 ms timeout is used so brief queue pressure is absorbed;
             * if the queue is still full, the entry stays in-flight and will
             * be reset by the inflight-timeout in event_outbox_tick(). */
            ESP_LOGI(TAG, "Event PUBACK msg_id=%d", event->msg_id);
            {
                esp_err_t puback_err = supervisor_submit_event_block(
                        EVENT_MQTT_PUBACK, (intptr_t)event->msg_id,
                        pdMS_TO_TICKS(50));
                if (puback_err != ESP_OK) {
                    ESP_LOGW(TAG, "PUBACK msg_id=%d dropped (supervisor queue full); "
                             "entry will recover via inflight timeout",
                             event->msg_id);
                }
            }
            break;
        default:
            break;
    }
    return;
}

esp_err_t mqtt_init()
{
    mqtt_wrapper_init();

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
        .event_handler = mqtt_event_handler,
        // Persistent session: broker retains subscriptions and queues QoS 1 messages while disconnected
        .disable_clean_session = true
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
    cJSON *bat_obj = cJSON_CreateObject();
    if (!bat_obj) {
        cJSON_Delete(root);
        return ESP_ERR_NO_MEM;
    }
    cJSON_AddNumberToObject(bat_obj, "usb", state->battery.usb_power_connected ? 1 : 0);
    cJSON_AddNumberToObject(bat_obj, "pg", state->battery.power_good ? 1 : 0);
    cJSON_AddNumberToObject(bat_obj, "con", state->battery.presence == BATTERY_PRESENCE_CONNECTED ? 1 : 0);
    cJSON_AddNumberToObject(bat_obj, "chg", (int)state->battery.charge_state == BATTERY_CHARGE_CHARGING ? 1 : 0);
    
    int pct = 0;
    switch(state->battery.level) {
        case BATTERY_LEVEL_FULL: pct = 100; break;
        case BATTERY_LEVEL_CRITICAL: pct = 10; break;
        case BATTERY_LEVEL_SHUTOFF: pct = 3; break;
        default: pct = 0; break;
    }
    cJSON_AddNumberToObject(bat_obj, "pct", pct);
    cJSON_AddItemToObject(root, "battery", bat_obj);
    cJSON *reload_obj = cJSON_CreateObject();
    if (!reload_obj) {
        cJSON_Delete(root);
        return ESP_ERR_NO_MEM;
    }
    if (state->reload_state.stage == RELOAD_NONE) {
        cJSON_AddBoolToObject(reload_obj, "needed", false);
    } else if (state->reload_state.stage == RELOAD_NEEDS_RELOAD) {
        cJSON_AddBoolToObject(reload_obj, "needed", true);
    } else {
        cJSON_AddBoolToObject(reload_obj, "needed", true);
        cJSON_AddNumberToObject(reload_obj, "progress", state->reload_state.progress);
        cJSON_AddNumberToObject(reload_obj, "complete_mask", state->reload_state.complete_mask);
    }
    cJSON_AddItemToObject(root, "reload", reload_obj);
    cJSON_AddNumberToObject(root, "doors", state->doors);
    cJSON_AddNumberToObject(root, "epoch_week", state->epoch_week);
    cJSON_AddNumberToObject(root, "error_flags", state->error_flags);
    cJSON_AddStringToObject(root, "fw_version", esp_app_get_description()->version);

    if (state->schedule.id[0] != '\0') {
        cJSON_AddStringToObject(root, "schedule_id", state->schedule.id);
    }

    if (state->timezone_iana[0] != '\0') {
        cJSON_AddStringToObject(root, "timezoneIana", state->timezone_iana);
    }

    if (state->timezone_posix[0] != '\0') {
        cJSON_AddStringToObject(root, "timezonePosix", state->timezone_posix);
    }

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

        if (state->bins[i].schedule_id[0] != '\0') {
            cJSON_AddStringToObject(bin_obj, "schedule_id", state->bins[i].schedule_id);
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
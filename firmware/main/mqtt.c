#include "mqtt.h"
#include "mqtt_wrapper.h"
#include "device_config.h"
#include "shadow_state.h"
#include "rtc.h"
#include "event_outbox.h"
#include <esp_log.h>
#include <inttypes.h>
#include <mqtt_client.h>
#include <cJSON.h>
#include <freertos/semphr.h>


#define TAG "MQTT"

static const char* s_cert_pem = NULL;
static const char* s_key_pem = NULL;

/* Mutex: prevent concurrent mqtt_drain_event_outbox() calls from
 * supervisor context and MQTT event handler context. */
static SemaphoreHandle_t s_drain_mutex = NULL;

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
        default:                    return "UNKNOWN";
    }
}

void mqtt_drain_event_outbox(void)
{
    /* Guard against concurrent drain calls from supervisor and MQTT event handler. */
    if (s_drain_mutex == NULL || xSemaphoreTake(s_drain_mutex, 0) != pdTRUE) {
        return;  /* Drain already in progress; skip */
    }

    if (!mqtt_wrapper_is_connected()) {
        xSemaphoreGive(s_drain_mutex);
        return;
    }

    char thing_name[128];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name for event drain");
        xSemaphoreGive(s_drain_mutex);
        return;
    }

    char topic[256];
    snprintf(topic, sizeof(topic), "healthe/things/%s/event", thing_name);

    /* Snapshot the connection epoch before any publish.  It is passed to
     * event_outbox_set_msg_id so that a racing MQTT_EVENT_DISCONNECTED is
     * detected and the stale packet ID is not written back. */
    uint64_t conn_epoch = event_outbox_get_conn_epoch();

    /* Load device state once before the loop; reused for every bin entry so
     * we avoid repeated NVS reads inside the per-entry body. */
    device_persistent_state_t dev_state;
    bool dev_state_loaded = (devcfg_get_device_state(&dev_state) == ESP_OK);

    /* Iterate without a snapshotted count: a concurrent MQTT_EVENT_PUBLISHED
     * can call event_outbox_ack() which pops from the front of the queue,
     * shifting all positions.  By restarting from i=0 after each successful
     * publish and breaking when event_outbox_get() returns ESP_ERR_NOT_FOUND,
     * we always see the current queue state and never skip an entry. */
    int i = 0;
    while (true) {
        event_outbox_entry_t entry;
        esp_err_t get_err = event_outbox_get(i, &entry);
        if (get_err == ESP_ERR_NOT_FOUND) {
            break;  /* reached the end of the queue */
        }
        if (get_err != ESP_OK) {
            xSemaphoreGive(s_drain_mutex);
            return;
        }

        /* Already delivered — never republish from the drain loop. */
        if (entry.delivered) { i++; continue; }
        /* Already published and awaiting PUBACK — skip. */
        if (entry.msg_id >= 0) { i++; continue; }

        cJSON *root = cJSON_CreateObject();
        if (!root) {
            xSemaphoreGive(s_drain_mutex);
            return;
        }

        cJSON_AddNumberToObject(root, "timestamp",  (double)entry.timestamp);
        cJSON_AddStringToObject(root, "event_type", event_type_to_str(entry.event_type));
        if (entry.bin_id != EVENT_OUTBOX_BIN_ID_NONE) {
            cJSON_AddNumberToObject(root, "bin_id", entry.bin_id);

            /* Include schedule_id for bin events, using the pre-loaded state. */
            if (dev_state_loaded &&
                entry.bin_id < DEVICE_NUM_BINS &&
                dev_state.bins[entry.bin_id].schedule_id[0] != '\0') {
                cJSON_AddStringToObject(root, "schedule_id",
                                        dev_state.bins[entry.bin_id].schedule_id);
            }
        }
        if (entry.flags != 0) {
            cJSON_AddNumberToObject(root, "flags", entry.flags);
        }

        char *json_str = cJSON_PrintUnformatted(root);
        cJSON_Delete(root);
        if (!json_str) break;

        int msg_id = -1;
        esp_err_t err = mqtt_wrapper_publish_with_id(topic, json_str,
                                                      strlen(json_str),
                                                      /*qos=*/1, /*retain=*/0,
                                                      &msg_id);
        free(json_str);

        if (err != ESP_OK || msg_id < 0) {
            ESP_LOGW(TAG, "Event drain: publish failed for seq=%" PRIu32 " (%d)", entry.seq, err);
            xSemaphoreGive(s_drain_mutex);
            return;  /* outgoing buffer likely full; retry on next drain call */
        }

        /* Record the client-assigned packet ID against the entry using its
         * stable sequence number as the key.  Passing conn_epoch lets the
         * outbox detect if a disconnect raced between publish and this call
         * and silently discard the write rather than recording a stale ID. */
        event_outbox_set_msg_id(entry.seq, msg_id, conn_epoch);
        ESP_LOGI(TAG, "Event drain: published seq=%" PRIu32 " msg_id=%d type=%s",
                 entry.seq, msg_id, event_type_to_str(entry.event_type));

        /* Restart from position 0: a concurrent PUBACK may have popped the
         * entry we just published (or an earlier one), shifting positions. */
        i = 0;
    }

    xSemaphoreGive(s_drain_mutex);
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
            /* Clear all pending msg_ids so every undelivered event is
             * republished when the connection is re-established. */
            event_outbox_reset_inflight();
            break;
        case MQTT_EVENT_PUBLISHED:
            /* Find the entry with this msg_id, mark it delivered, and pop
             * all consecutive delivered entries from the front.  Then kick
             * the drain loop to publish any remaining entries. */
            if (event_outbox_ack(event->msg_id) == ESP_OK) {
                ESP_LOGI(TAG, "Event PUBACK msg_id=%d", event->msg_id);
                mqtt_drain_event_outbox();
            }
            break;
        default:
            break;
    }
    return;
}

esp_err_t mqtt_init()
{
    /* Create mutex if not already created */
    if (s_drain_mutex == NULL) {
        s_drain_mutex = xSemaphoreCreateMutex();
        if (s_drain_mutex == NULL) {
            ESP_LOGE(TAG, "Failed to create drain mutex");
            return ESP_ERR_NO_MEM;
        }
    }

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

    if (state->schedule.id[0] != '\0') {
        cJSON_AddStringToObject(root, "schedule_id", state->schedule.id);
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
#include "iot_telemetry.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "mqtt_handler.h"
#include "pill_state.h"
#include "pill_types.h"
#include "network.h"
#include "event.h"
#include "sdkconfig.h"
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "cJSON.h"

#define TAG "IOT_TELEMETRY"

// Topic: /tenant/{tenantId}/{deviceId}/bins/state
static char s_topic[256] = {0};

static EventGroupHandle_t s_telemetry_event_group;
#define BIN_STATE_CHANGED_BIT (1 << 0)
static uint16_t s_latest_bitmask = 0;

static void build_topic(void)
{
    char thing[128];
    network_load_thing_name(thing, sizeof(thing));

    snprintf(s_topic, sizeof(s_topic),
             "healthe/things/%s/state", thing);
    ESP_LOGI(TAG, "Bin state topic: %s", s_topic);
}

void iot_telemetry_publish_bin_state(uint16_t bitmask)
{
    if (!mqtt_is_connected()) {
        return;
    }

    struct timeval tv;
    gettimeofday(&tv, NULL);
    // Combine seconds and microseconds into a 64-bit integer (milliseconds)
    int64_t time_ms = (int64_t)tv.tv_sec * 1000LL + (int64_t)tv.tv_usec / 1000LL;

    /* Build json into payload using cJSON */
    cJSON *root = cJSON_CreateObject();
    if (root == NULL) {
        ESP_LOGE(TAG, "Failed to create cJSON root object");
        return;
    }

    cJSON_AddStringToObject(root, "id", "test");
    // Cast time_ms to double; safe as ms timestamps fit within 53-bit float precision
    cJSON_AddNumberToObject(root, "lastSync", (double)time_ms);
    cJSON_AddNumberToObject(root, "bins", bitmask);

    // Create an empty array for dosePeriods
    cJSON *dose_periods = cJSON_CreateArray();
    cJSON_AddItemToObject(root, "dosePeriods", dose_periods);

    // Hardcoded battery states based on template
    cJSON_AddNumberToObject(root, "battery", 100);
    cJSON_AddBoolToObject(root, "charging", true);

    // Generate minified JSON string to save bandwidth
    char *json_string = cJSON_PrintUnformatted(root);
    if (json_string == NULL) {
        ESP_LOGE(TAG, "Failed to print cJSON object");
        cJSON_Delete(root);
        return;
    }

    char payload[512];
    int pos = snprintf(payload, sizeof(payload), "%s", json_string);

    // Free cJSON memory to prevent leaks
    cJSON_free(json_string);
    cJSON_Delete(root);

    // Verify the payload fits our buffer securely
    if (pos < 0 || pos >= sizeof(payload)) {
        ESP_LOGE(TAG, "Payload truncated or snprintf failed");
        return;
    }

    esp_err_t err = mqtt_publish(s_topic, payload, pos);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "Published bin state (%d bytes)", pos);
    } else {
        ESP_LOGE(TAG, "Failed to publish bin state");
    }
}

static void telemetry_task(void *arg)
{
    while (1) {
        EventBits_t bits = xEventGroupWaitBits(s_telemetry_event_group,
                                               BIN_STATE_CHANGED_BIT,
                                               pdTRUE,
                                               pdFALSE,
                                               portMAX_DELAY);

        if (bits & BIN_STATE_CHANGED_BIT) {
            iot_telemetry_publish_bin_state(s_latest_bitmask);
        }
    }
}

static void bin_event_handler(void* event_handler_arg, esp_event_base_t event_base,
                            int32_t event_id, void* event_data)
{
    if(event_base == BIN_EVENT_BASE) {
        if(event_id == BIN_EVENT_BITMASK_CHANGED) {
            BinEventBitmaskChanged* changed = (BinEventBitmaskChanged*)event_data;
            s_latest_bitmask = changed->bitmask;
            if (s_telemetry_event_group) {
                xEventGroupSetBits(s_telemetry_event_group, BIN_STATE_CHANGED_BIT);
            }
        }
    }
}

esp_err_t iot_telemetry_start(void)
{
    build_topic();

    s_telemetry_event_group = xEventGroupCreate();
    if (s_telemetry_event_group == NULL) {
        ESP_LOGE(TAG, "Failed to create event group");
        return ESP_FAIL;
    }

    // Create task with sufficient stack for MQTT/TLS operations (6KB)
    xTaskCreate(telemetry_task, "Telemetry Task", 6144, NULL, 5, NULL);

    event_register_handler(bin_event_handler, NULL, BIN_EVENT_BASE);
    ESP_LOGI(TAG, "Telemetry started");
    return ESP_OK;
}
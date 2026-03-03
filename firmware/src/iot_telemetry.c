#include "iot_telemetry.h"
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

#define TAG "IOT_TELEMETRY"

#ifndef CONFIG_DEV_CLAIM_TENANT_ID
#define TENANT_ID "public"
#else
#define TENANT_ID CONFIG_DEV_CLAIM_TENANT_ID
#endif

// Topic: /tenant/{tenantId}/{deviceId}/bins/state
static char s_topic[128] = {0};

static void build_topic(void)
{
    uint8_t sn[6];
    size_t sn_len = 0;
    network_get_serial_number(sn, &sn_len);

    char device_id[32];
    snprintf(device_id, sizeof(device_id),
             "ESP32-%02X%02X%02X%02X%02X%02X",
             sn[0], sn[1], sn[2], sn[3], sn[4], sn[5]);

    snprintf(s_topic, sizeof(s_topic),
             "/tenant/%s/%s/bins/state",
             TENANT_ID, device_id);

    ESP_LOGI(TAG, "Bin state topic: %s", s_topic);
}

void iot_telemetry_publish_bin_state(void)
{
    if (!mqtt_is_connected()) {
        return;
    }

    // Serialise all 14 bin states into one JSON object.
    // Payload example:
    // {"ts":1740000000,"bins":[{"id":0,"status":3,"scheduled":1740001000}, ...]}
    char payload[512];
    int  pos = 0;

    time_t now;
    time(&now);

    pos += snprintf(payload + pos, sizeof(payload) - pos,
                    "{\"ts\":%lld,\"bins\":[", (long long)now);

    const bin_state_t* bins = state_acquire_ro();
    for (bin_id_t i = 0; i < BIN_COUNT; i++) {
        pos += snprintf(payload + pos, sizeof(payload) - pos,
                        "%s{\"id\":%d,\"status\":%d,\"scheduled\":%lld}",
                        i == 0 ? "" : ",",
                        i,
                        bins[i].status,
                        (long long)bins[i].schedule_time);
    }
    state_release_ro(bins);

    pos += snprintf(payload + pos, sizeof(payload) - pos, "]}");

    esp_err_t err = mqtt_publish(s_topic, payload, pos);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "Published bin state (%d bytes)", pos);
    } else {
        ESP_LOGE(TAG, "Failed to publish bin state");
    }
}

static void bin_event_handler(void* arg, esp_event_base_t base,
                              int32_t id, void* event_data)
{
    iot_telemetry_publish_bin_state();
}

esp_err_t iot_telemetry_start(void)
{
    build_topic();
    event_register_handler_id(bin_event_handler, NULL, BIN_EVENT_BASE, BIN_EVENT);
    ESP_LOGI(TAG, "Telemetry started");
    return ESP_OK;
}
#include "iot_telemetry.h"
#include "engineering.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "mqtt_handler.h"

#define TAG "IOT_TELEMETRY"
#define HEARTBEAT_INTERVAL_US (10 * 1000000) // 10 seconds

static esp_timer_handle_t heartbeat_timer;
extern bool telemetry_heartbeat_active;

static void heartbeat_timer_callback(void* arg) {
    if (!telemetry_heartbeat_active) {
        ESP_LOGD(TAG, "Heartbeat skipped (Disabled via Engineering Page)");
        return; 
    }
    
    publish_bin_voltage_json(0);  // Publish bin 0
}

void publish_bin_voltage_json(int bin_id) {
    uint32_t mv = engineering_get_bin_voltage(bin_id);

    // Construct AWS Shadow JSON
    char payload[128];
    snprintf(payload, sizeof(payload),
        "{\"state\":{\"reported\":{\"bin_%d_mv\":%lu}}}", 
        bin_id, (unsigned long)mv);

    // Publish using AWS IoT SDK
    if (mqtt_is_connected()) {
        esp_err_t err = mqtt_publish_shadow_update(payload);
        
        if (err == ESP_OK) {
            ESP_LOGW(TAG, ">>> SHADOW PUBLISHED: %s", payload);
        } else {
            ESP_LOGE(TAG, ">>> PUBLISH FAILED");
        }
    } else {
        ESP_LOGE(TAG, ">>> MQTT not connected yet");
    }
}

esp_err_t iot_telemetry_start() {
    const esp_timer_create_args_t timer_args = {
        .callback = &heartbeat_timer_callback,
        .name = "heartbeat"
    };

    esp_err_t err = esp_timer_create(&timer_args, &heartbeat_timer);
    if (err != ESP_OK) return err;

    ESP_LOGI(TAG, "Telemetry heartbeat started (10s interval)");
    return esp_timer_start_periodic(heartbeat_timer, HEARTBEAT_INTERVAL_US);
}

void iot_telemetry_stop() {
    if (heartbeat_timer) {
        esp_timer_stop(heartbeat_timer);
        esp_timer_delete(heartbeat_timer);
        ESP_LOGI(TAG, "Telemetry heartbeat stopped");
    }
}
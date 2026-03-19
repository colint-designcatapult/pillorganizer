#include "mqtt.h"
#include "mqtt_wrapper.h"
#include "device_config.h"
#include <esp_log.h>
#include <mqtt_client.h>


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

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    switch (event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "MQTT Connected");
            cleanup_certs();
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
    
    esp_err_t err = mqtt_wrapper_connect(&mqtt_cfg);
    if (err != ESP_OK) {
        cleanup_certs();
    }
    return err;
}
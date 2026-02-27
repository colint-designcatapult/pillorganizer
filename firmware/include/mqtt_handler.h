#ifndef MQTT_HANDLER_H
#define MQTT_HANDLER_H

#include "esp_err.h"
#include <stdbool.h>
#include "sdkconfig.h"

#ifndef CONFIG_AWS_IOT_ENDPOINT
#define AWS_IOT_ENDPOINT "mqtt.app.healthesolutions.ca"
#else
#define AWS_IOT_ENDPOINT CONFIG_AWS_IOT_ENDPOINT
#endif

#ifndef CONFIG_AWS_IOT_THING_NAME
#define THING_NAME "PillOrganizer_Test_001"
#else
#define THING_NAME CONFIG_AWS_IOT_THING_NAME
#endif

/**
 * @brief Initializes and starts the MQTT connection to AWS IoT Core
 */
void mqtt_app_start(void);

/**
 * @brief Check if MQTT is connected to AWS IoT
 */
bool mqtt_is_connected(void);

/**
 * @brief Publish a Device Shadow update to AWS IoT
 * @param json_payload The JSON payload (e.g., {"state":{"reported":{...}}})
 * @return ESP_OK on success, ESP_FAIL on failure
 */
esp_err_t mqtt_publish_shadow_update(const char* json_payload);

#endif
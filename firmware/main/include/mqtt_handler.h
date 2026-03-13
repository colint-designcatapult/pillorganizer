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

/**
 * @brief Connect to AWS IoT with dynamic certificates
 * @param client_id MQTT client ID (serial number or Thing name)
 * @param root_ca Root CA certificate PEM string
 * @param device_cert Device certificate PEM string
 * @param device_key Device private key PEM string
 * @return ESP_OK on success, ESP_FAIL on failure
 */
esp_err_t mqtt_connect_with_certs(const char* client_id, const char* root_ca, 
                                   const char* device_cert, const char* device_key);

/**
 * @brief Subscribe to an MQTT topic with callback
 * @param topic Topic to subscribe to
 * @param callback Function to call when message received on this topic
 * @return ESP_OK on success, ESP_FAIL on failure
 */
typedef void (*mqtt_message_callback_t)(const char* topic, const char* payload, size_t len);
esp_err_t mqtt_subscribe(const char* topic, mqtt_message_callback_t callback);

/**
 * @brief Publish to an arbitrary MQTT topic
 * @param topic Topic to publish to
 * @param payload Payload data
 * @param len Payload length
 * @return ESP_OK on success, ESP_FAIL on failure
 */
esp_err_t mqtt_publish(const char* topic, const char* payload, size_t len);

/**
 * @brief Disconnect from MQTT broker
 * @return ESP_OK on success, ESP_FAIL on failure
 */
esp_err_t mqtt_disconnect(void);

#endif
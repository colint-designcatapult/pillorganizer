#pragma once

#include "esp_err.h"

/**
 * @brief Initializes the telemetry timer and MQTT hooks.
 */
esp_err_t iot_telemetry_start();

/**
 * @brief Stops the 10-second heartbeat.
 */
void iot_telemetry_stop();

/**
 * @brief Publishes the voltage of a specific bin as JSON.
 */
void publish_bin_voltage_json(int bin_id);
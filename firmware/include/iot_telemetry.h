#pragma once

#include "esp_err.h"

/**
 * @brief Registers the bin event handler and starts telemetry.
 */
esp_err_t iot_telemetry_start(void);

/**
 * @brief Publishes all 14 bin states to /tenant/{id}/{device}/bins/state.
 */
void iot_telemetry_publish_bin_state(uint16_t);
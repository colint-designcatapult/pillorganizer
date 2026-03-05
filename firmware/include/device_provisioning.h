#pragma once

#include "esp_err.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Start AWS IoT Fleet Provisioning workflow
 * @return ESP_OK on success, ESP_FAIL on error, ESP_ERR_INVALID_STATE if already provisioned
 */
esp_err_t device_provisioning_start(void);

/**
 * @brief Check if device is already provisioned
 * 
 * @return true if device has permanent credentials in NVS, false otherwise
 */
bool device_provisioning_is_provisioned(void);

/**
 * @brief Clear all provisioning credentials from NVS, forcing re-provisioning on next boot
 */
void device_provisioning_clear(void);

#ifdef __cplusplus
}
#endif

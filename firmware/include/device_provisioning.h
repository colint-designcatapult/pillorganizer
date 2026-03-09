#pragma once

#include "esp_err.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Start AWS IoT Fleet Provisioning workflow using temporary certificates
 *        fetched from the control plane. Temp certs are kept in RAM only.
 * @param claim_cert_pem  Temporary certificate PEM from control plane HTTP POST
 * @param claim_key_pem   Temporary private key PEM from control plane HTTP POST
 * @param claim_token_param  The claimToken received from the app (used as RegThing param)
 * @return ESP_OK on success, ESP_FAIL on error, ESP_ERR_INVALID_STATE if already provisioned
 */
esp_err_t device_provisioning_start(const char* claim_cert_pem, const char* claim_key_pem,
                                     const char* claim_id_param, const char* claim_token_param);

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

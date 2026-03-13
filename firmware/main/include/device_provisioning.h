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

/**
 * @brief Mark provisioning as complete/successful by setting a flag in NVS.
 *        This proves the entire flow (CreateKeys + RegisterThing + reconnection) completed.
 *        Only call this after successful reconnection with permanent credentials.
 */
void device_provisioning_mark_success(void);

/**
 * @brief Check if provisioning was previously marked successful.
 *        If certs exist but this flag doesn't, they are orphaned/invalid.
 * @return true if success flag exists, false otherwise
 */
bool device_provisioning_is_complete(void);

/**
 * @brief Record MQTT auth failure start time (first failure detected).
 *        Call this when MQTT connection first fails.
 *        Only records timestamp if not already set (idempotent).
 */
void mqtt_record_auth_failure_start(void);

/**
 * @brief Check if MQTT auth failure has persisted for more than X hours.
 * @param hours Number of hours to check against
 * @return true if failure started AND more than 'hours' have elapsed
 */
bool mqtt_check_auth_failure_timeout(uint32_t hours);

/**
 * @brief Clear MQTT auth failure timestamp (call after successful connection).
 */
void mqtt_clear_auth_failure_record(void);

#ifdef __cplusplus
}
#endif

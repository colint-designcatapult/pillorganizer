#pragma once

#include "esp_err.h"
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Fleet provisioning status — set by fleet_provisioning_task, polled by app via BLE
typedef enum {
    FLEET_PROV_STATUS_IDLE = 0,
    FLEET_PROV_STATUS_PENDING,
    FLEET_PROV_STATUS_SUCCESS,
    FLEET_PROV_STATUS_FAILED
} fleet_prov_status_t;

// BLE endpoint handlers — registered with wifi_provisioning manager in wifi.cpp
esp_err_t ble_endpoint_device_serial(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen, uint8_t **outbuf, ssize_t *outlen, void *priv_data);
esp_err_t ble_endpoint_wifi_connection_status(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen, uint8_t **outbuf, ssize_t *outlen, void *priv_data);
esp_err_t ble_endpoint_device_claim_token_set(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen, uint8_t **outbuf, ssize_t *outlen, void *priv_data);
esp_err_t ble_endpoint_fleet_provisioning_status(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen, uint8_t **outbuf, ssize_t *outlen, void *priv_data);

// Claim credential state — populated by ble_endpoint_device_claim_token_set
bool wifi_claim_credentials_received(void);
void wifi_get_claim_credentials(char *claim_id_out, size_t claim_id_len,
                                 char *claim_token_out, size_t claim_token_len);
void wifi_reset_claim_credentials(void);

// Fleet provisioning status accessors
fleet_prov_status_t wifi_get_fleet_provisioning_status(void);
void wifi_set_fleet_provisioning_status(fleet_prov_status_t status);

#ifdef __cplusplus
}
#endif

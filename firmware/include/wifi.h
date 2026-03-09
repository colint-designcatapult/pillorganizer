#pragma once
#include <freertos/FreeRTOS.h>
#include <freertos/event_groups.h>

// 2 distinct bits so that we can wait on disconnect events
#define WIFI_BIT_CONNECTED	    ( 1 << 1 )
#define WIFI_BIT_DISCONNECTED	( 1 << 2 )

#ifdef __cplusplus
extern "C" {
#endif

#include "pill_types.h"

void wifi_init_early();
void wifi_init();

EventGroupHandle_t wifi_event_group();

/* Return false if timed out */
bool wifi_wait_for_connection(TickType_t ticks_to_wait);
bool wifi_wait_for_disconnect(TickType_t ticks_to_wait);

bool wifi_is_connected();

const wifi_info_t* wifi_get_info();

/* Check if app acknowledged receipt of device serial number */
bool wifi_device_serial_acknowledged();

/* Reset the serial acknowledgement flag */
void wifi_reset_serial_acknowledgement();

/* Check if app has sent claim credentials (claimId and claimToken) */
bool wifi_claim_credentials_received();

/* Retrieve claim credentials sent by app */
void wifi_get_claim_credentials(char *claim_id_out, size_t claim_id_len,
                                 char *claim_token_out, size_t claim_token_len);

/* Reset claim credentials (for next provisioning cycle) */
void wifi_reset_claim_credentials();

/* Fleet provisioning status - updated by fleet_provisioning_task, polled by app via BLE endpoint */
typedef enum {
    FLEET_PROV_STATUS_IDLE = 0,    // BLE provisioning not yet complete
    FLEET_PROV_STATUS_PENDING,     // Claim credentials received, fleet provisioning in progress
    FLEET_PROV_STATUS_SUCCESS,     // Successfully registered with AWS IoT Core
    FLEET_PROV_STATUS_FAILED       // Failed - device will clear WiFi and restart
} fleet_prov_status_t;

fleet_prov_status_t wifi_get_fleet_provisioning_status(void);
void wifi_set_fleet_provisioning_status(fleet_prov_status_t status);
void wifi_deinit_provisioning(void);

#ifdef __cplusplus
}
#endif
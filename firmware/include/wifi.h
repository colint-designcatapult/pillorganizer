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
#include "ble_endpoints.h"

void wifi_init_early();
void wifi_init();

EventGroupHandle_t wifi_event_group();

/* Return false if timed out */
bool wifi_wait_for_connection(TickType_t ticks_to_wait);
bool wifi_wait_for_disconnect(TickType_t ticks_to_wait);

bool wifi_is_connected();
bool wifi_is_credential_failed(void);

const wifi_info_t* wifi_get_info();

/* Check if app acknowledged receipt of device serial number */
bool wifi_device_serial_acknowledged();

/* Reset the serial acknowledgement flag */
void wifi_reset_serial_acknowledgement();

void wifi_deinit_provisioning(void);

#ifdef __cplusplus
}
#endif
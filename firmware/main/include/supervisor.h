/* 
 * Supervisor
 * 
 */
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <esp_err.h>
#include <freertos/FreeRTOS.h>
#include "rtc.h"

/* --- CURRENT STATE --- */

typedef enum {
    STATE_INIT,
    STATE_UNPROVISIONED,
    STATE_PROVISIONING,
    STATE_CONNECTING_NETIF,
    STATE_SYNCING_TIME,
    STATE_FETCHING_CERT,
    STATE_FLEET_PROVISIONING,
    STATE_OPERATIONAL,
    STATE_MQTT_DISCONNECTED
} supervisor_state_t;

/* --- EVENTS (State Transition Edges) --- */

typedef enum {
    /* Device init & provision */
    EVENT_PROVISION_STARTED,
    EVENT_PROVISION_WIFI_SUCCESS,
    EVENT_PROVISION_FAILED,
    EVENT_NETIF_CONNECTED,
    EVENT_NETIF_DISCONNECTED,
    EVENT_CLAIM_CREDENTIALS_RECEIVED,
    EVENT_CERT_CLAIM_SUCCESS,
    EVENT_CERT_CLAIM_FAILED,
    EVENT_TIME_SYNCED,
    EVENT_FLEET_PROVISION_SUCCESS,
    EVENT_FLEET_PROVISION_FAILED,
    EVENT_FLEET_PROVISION_DEINIT,
    EVENT_MQTT_CONNECTED,
    EVENT_MQTT_DISCONNECTED,

    /* Operational events */
    EVENT_STATE_CHANGED,
    EVENT_DOOR_OPENED,
    EVENT_DOOR_CLOSED,
    EVENT_BIN_TAKEN,
    EVENT_BIN_MISSED,
    EVENT_BIN_TAKE_NOW,
    EVENT_RELOAD_START,
    EVENT_RELOAD_END,
    EVENT_ACTION_TIMEOUT
} supervisor_event_id_t;

typedef struct {
    supervisor_event_id_t id;
    void* payload; // optional
} supervisor_event_t;

typedef int supervisor_event_door_t;
// Pack event into payload void*, make sure it fits
static_assert(sizeof(supervisor_event_door_t) <= sizeof(void*));

/* --- OPERATIONAL STATE --- */

typedef enum {
    DISABLED,
    TAKEN,
    MISSED,
    PENDING,
    TAKE_NOW
} bin_status_t;

typedef struct {
    bin_status_t status;
    // Unix timestamp (UTC) in milliseconds of the scheduled time the medication in this bin is taken at.
    uint64_t scheduled_time;
    // Unix timestamp (UTC) in milliseconds of the last recorded update to this bin's state.
    uint64_t event_time;
    // The ID of the schedule this bin is programmed for.
    const char* schedule_id;
    // Bin open timestamp
    rtc_relative_time_t opened_at;
    // Bin close timestamp
    rtc_relative_time_t closed_at;
} bin_state_t;

typedef struct {
    // Last modify timestamp
    rtc_relative_time_t timestamp;
    // Battery percentage, out of 100
    uint8_t battery;
    // Battery charging status
    bool charging;
    // Whether the device is executing a reload
    bool reloading;
    // An integer acting as a bitfield to track door states
    // Each bit corresponds to a specific bin door, read from the Least Significant Bit (LSB) upwards.
    int doors;
    // State of each bin
    bin_state_t bins[14];
} device_state_t;


void supervisor_init();
void supervisor_run();

esp_err_t supervisor_submit_event_block(supervisor_event_id_t event_id, void* payload, TickType_t ticks_to_wait);
esp_err_t supervisor_submit_event(supervisor_event_id_t event_id);

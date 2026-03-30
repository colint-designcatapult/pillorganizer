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
#include "device_config.h"


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
    EVENT_SHADOW_READY,
    

    /* Operational events */
    EVENT_STATE_CHANGED,
    EVENT_DOOR_OPENED,
    EVENT_DOOR_CLOSED,
    EVENT_BIN_TAKEN,
    EVENT_BIN_MISSED,
    EVENT_BIN_TAKE_NOW,
    EVENT_RELOAD_START,
    EVENT_RELOAD_END,
    EVENT_ACTION_TIMEOUT,
    EVENT_LED_EFFECT_COMPLETE,
    EVENT_REBOOT_REQUESTED,
    EVENT_FAILSAFE,
    EVENT_SCHEDULE_DELTA_RECEIVED,
} supervisor_event_id_t;

typedef struct {
    supervisor_event_id_t id;
    intptr_t payload; // optional
} supervisor_event_t;

typedef int supervisor_event_door_t;
// Pack event into payload void*, make sure it fits
static_assert(sizeof(supervisor_event_door_t) <= sizeof(intptr_t));

/* ----- OPERATIONAL STATE ------ */

typedef struct {
    bin_status_t status;
    // Unix timestamp (UTC) in seconds of the scheduled time the medication in this bin is taken at.
    time_t scheduled_time;
    // Unix timestamp (UTC) in milliseconds of the last recorded update to this bin's state.
    rtc_utc_timestamp_ms event_time;
    // Bin open timestamp
    rtc_relative_time_t opened_at;
    // Bin close timestamp
    rtc_relative_time_t closed_at;
    // The ID of the schedule this bin is programmed for.
    char schedule_id[SCHEDULE_ID_SIZE];
} bin_state_t;

typedef enum {
    DEVICE_OPERATIONAL,
    FAILSAFE_NEED_RELOAD,           // Device is empty and needs to be reloaded with medication
    FAILSAFE_NO_SCHEDULE,           // Device isn't programmed with a schedule
    FAILSAFE_STATE_CORRUPTED,       // Existing state exists in NVS, but corrupted
    FAILSAFE_NO_RTC_TIME            // Accurate real-time clock time unavailable when needed
} device_failsafe_reason_t;

#define SECONDS_PER_WEEK 604800

typedef struct {
    // Time state last modified at
    rtc_utc_timestamp_ms modified_at;
    // Time state last synced
    rtc_utc_timestamp_ms synced_at;
    // Battery percentage, out of 100
    uint8_t battery;
    // Battery charging status
    bool charging;
    // Whether the device is executing a reload
    bool reloading;
    // If the device is in failsafe mode, the reason why
    device_failsafe_reason_t failsafe_reason;
    // An integer acting as a bitfield to track door states
    // Each bit corresponds to a specific bin door, read from the Least Significant Bit (LSB) upwards.
    int doors;
    // State of each bin
    bin_state_t bins[14];
    // Schedule programmed on the device
    device_schedule_t schedule;
    // Start of the "week" at 00:00:00 UTC as a Unix timestamp (seconds)
    time_t epoch_week;
} device_state_t;

void supervisor_init();
void supervisor_run();

esp_err_t supervisor_submit_event_block(supervisor_event_id_t event_id, intptr_t payload, TickType_t ticks_to_wait);
esp_err_t supervisor_submit_event(supervisor_event_id_t event_id);

// Resets just the stored Wi-Fi credentials. Does not wipe the device identity.
void supervisor_reset_wifi();
// Fully wipes NVS to clean state, including Wi-Fi credentials and device identity.
void supervisor_factory_reset();

// Gets a *copy* of the current schedule, if it exists
esp_err_t supervisor_get_schedule(device_schedule_t* sched);
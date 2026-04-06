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
#include "battery.h"


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
    EVENT_ACTION_TIMEOUT,
    EVENT_LED_EFFECT_COMPLETE,
    EVENT_REBOOT_REQUESTED,
    EVENT_ERROR_CONDITION,
    EVENT_ERROR_CLEARED,
    EVENT_SCHEDULE_DELTA_RECEIVED,
    EVENT_RELOAD_TIMEOUT,
    EVENT_RELOAD_COMPLETE,
    EVENT_BATTERY_CHANGE,
    EVENT_RESET_PENDING_BINS
} supervisor_event_id_t;

typedef struct {
    supervisor_event_id_t id;
    intptr_t payload; // optional
} supervisor_event_t;

typedef int supervisor_event_door_t;
// Pack event into payload void*, make sure it fits
static_assert(sizeof(supervisor_event_door_t) <= sizeof(intptr_t));


/* ----- OPERATIONAL STATE ------ */

typedef enum {
    BIN_FLAG_NONE       = 0,
    BIN_FLAG_OPEN       = (1 << 0),
    BIN_FLAG_ON_TIME    = (1 << 1)
} bin_state_flags_t;

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
    int flags;
} bin_state_t;

typedef enum {
    DEVERR_NONE             =  0,
    DEVERR_NO_SCHEDULE      =  (1 << 0),
    DEVERR_STATE_CORRUPTED  =  (1 << 1),
    DEVERR_NO_RTC_TIME      =  (1 << 2)
} device_error_flag_t;

#define SECONDS_PER_WEEK 604800

typedef enum {
    RELOAD_NONE,
    RELOAD_NEEDS_RELOAD,
    RELOAD_RELOADING,
} device_reload_stage_t;

typedef struct device_state_t device_state_t;

typedef struct {
    device_reload_stage_t stage;
    uint16_t progress;                  // Current reload bin mask
    uint16_t complete_mask;             // Bin mask needed for the reload to be complete
    rtc_relative_time_t start_time;
    rtc_relative_time_t end_time;
    device_state_t* future_state;
} device_reload_state_t;

typedef struct device_state_t {
    // Time state last modified at
    rtc_utc_timestamp_ms modified_at;
    // Time state last synced
    rtc_utc_timestamp_ms synced_at;
    // Battery status
    battery_state_t battery;
    // State of the device reload process
    device_reload_state_t reload_state;
    // An integer acting as a bitfield to track door states
    // Each bit corresponds to a specific bin door, read from the Least Significant Bit (LSB) upwards.
    int doors;
    // State of each bin
    bin_state_t bins[14];
    // Schedule programmed on the device
    device_schedule_t schedule;
    // Start of the "week" at local Monday 00:00:00 (device time zone), stored as a Unix timestamp (seconds)
    time_t epoch_week;
    // Non-authoritative copy of the device error flags
    int error_flags;
    // Length of the schedule in days (e.g., 7 for a weekly schedule)
    uint8_t schedule_length_days;
} device_state_t;

typedef enum {
    DEVEVT_DOOR_OPENED,
    DEVEVT_DOOR_CLOSED,
    DEVEVT_TAKEN,
    DEVEVT_MISSED,
    DEVEVT_TAKE_NOW,
    DEVEVT_RELOAD_START,
    DEVEVT_RELOAD_END,
    DEVEVT_ACTION_TIMEOUT,
} device_event_type_t;

typedef struct {
    rtc_utc_timestamp_ms timestamp;
    device_event_type_t event_type;
    int bin_id;
} device_event_t;

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

void supervisor_assert_error(device_error_flag_t error);
void supervisor_clear_error(device_error_flag_t error);
device_error_flag_t supervisor_get_error_flags();
/* 
 * Device Configuration
 * 
 */
#pragma once
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <esp_err.h>
#include "rtc.h"

#define SERIAL_NUMBER_SIZE 6
#define SERIAL_NUMBER_STR_SIZE 13

void devcfg_init();
void devcfg_get_serial_number(uint8_t sn[SERIAL_NUMBER_SIZE], size_t size);
void devcfg_get_serial_number_str(char serial_number[SERIAL_NUMBER_STR_SIZE], size_t size);

bool devcfg_has_permanent_identity();
void devcfg_reset_identity();

bool devcfg_get_thing_name_str(char* thing_name_out, size_t size);
esp_err_t devcfg_set_thing_name(const char* thing_name);

// Retrieves the permanent private key from NVS. 
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_key();

// Retrieves the permanent certificate from NVS. 
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_cert();

esp_err_t devcfg_set_permanent_cert(const char* cert, const char* privkey);


/* --- DEVICE SCHEDULE --- */

#define SCHEDULE_ID_SIZE 37

typedef enum {
    SCHED_MONDAY, SCHED_TUESDAY, SCHED_WEDNESDAY, SCHED_THURSDAY, SCHED_FRIDAY, SCHED_SATURDAY, SCHED_SUNDAY
} device_schedule_day_of_week_t;

typedef enum {
    SCHED_IMMEDIATE, SCHED_NEXT_RELOAD
} device_schedule_take_effect_t;

typedef enum {
    SCHED_NONE,
    SCHED_SIMPLE
} device_schedule_type_t;

typedef enum {
    SCHED_VALID,
    SCHED_ERR_UNSUPPORTED_TYPE,
    SCHED_ERR_TOO_MANY_PERIODS,
    SCHED_ERR_TOO_MANY_PERIODS_IN_DAY,
    SCHED_ERR_APPLY_FAILED
} device_schedule_validation_t;

typedef struct {
    device_schedule_day_of_week_t day_of_week;
    uint8_t hour;
    uint8_t minute;
} device_bin_schedule_t;

typedef struct {
    char id[SCHEDULE_ID_SIZE];
    device_schedule_type_t type;
    union {
        struct {
            uint8_t bin_count; // Track active bins
            device_bin_schedule_t bins[14];
        } simple_schedule;
    } schedule;
    device_schedule_take_effect_t take_effect;
    char rejected_id[SCHEDULE_ID_SIZE];
    device_schedule_validation_t rejected_reason;
} device_schedule_t;

esp_err_t devcfg_get_device_schedule(device_schedule_t* state);
esp_err_t devcfg_set_device_schedule(const device_schedule_t* state);


/* --- OPERATIONAL STATE --- */

typedef enum {
    DISABLED,
    TAKEN,
    MISSED,
    PENDING,
    TAKE_NOW,
    NO_RECORD
} bin_status_t;

typedef struct {
    bin_status_t status;
    // Unix timestamp (UTC) in seconds of the scheduled time the medication in this bin is taken at.
    time_t scheduled_time;
    // Unix timestamp (UTC) in milliseconds of the last recorded update to this bin's state.
    rtc_utc_timestamp_ms event_time;
    // The ID of the schedule this bin is programmed for.
    char schedule_id[SCHEDULE_ID_SIZE];
} bin_persistent_state_t;

// Device state information that must be preserved in NVS and between boots
typedef struct {
    // Last persistent state change timestamp
    rtc_utc_timestamp_ms modified_at;
    // Last time state was synced with server
    rtc_utc_timestamp_ms synced_at;
    // Schedule programmed on the device
    device_schedule_t schedule;
    // State of each bin
    bin_persistent_state_t bins[14];
    // Start of the "week" at 00:00:00 UTC as a Unix timestamp (seconds)
    time_t epoch_week;
} device_persistent_state_t;


esp_err_t devcfg_get_device_state(device_persistent_state_t* state);
esp_err_t devcfg_set_device_state(const device_persistent_state_t* state);

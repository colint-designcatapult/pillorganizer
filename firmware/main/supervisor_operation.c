#include "supervisor_operation.h"
#include <string.h>
#include <esp_log.h>
#include <esp_ota_ops.h>
#include <esp_app_desc.h>
#include "mqtt.h"
#include "device_config.h"
#include "ledc.h"
#include "network.h"
#include "shadow_state.h"
#include "ota.h"
#include "event_outbox.h"
#include "sleep_state.h"
#include <stdatomic.h>
#include "sdkconfig.h"
#if !CONFIG_EMULATOR_MODE
#include "esp_sleep.h"
#include "mux_io.h"
#endif

#define TAG "SUPERVISOR_OPERATION"
#define DOOR_LEFT_OPEN_TIMEOUT_MS 60000  /* 60 seconds */

typedef enum {
    STATE_INIT,
    STATE_CONNECTING_NETIF,
    STATE_SYNCING_TIME,
    STATE_CONNECTING_MQTT,
    STATE_MQTT_CONNECTED,
    STATE_OPERATIONAL,
    STATE_OTA,
} supervisor_operation_state_t;

static atomic_bool s_init = ATOMIC_VAR_INIT(false);
static supervisor_operation_state_t s_state;
device_state_t s_device_state;

typedef enum {
    DEFERRED_NONE,
    DEFERRED_OTA,
    DEFERRED_SLEEP,   /* reserved for future deep sleep support */
} deferred_action_t;

static deferred_action_t s_pending_deferred = DEFERRED_NONE;

static int MISSED_THRESHOLD_SEC = 15 * 60;  // 15 minutes (15 * 60 seconds)
static int RELOAD_TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes (5 * 60 seconds * 1000 ms)
#define IDLE_SLEEP_TIMEOUT_MS (60 * 1000)  // 1 minute of OPERATIONAL idle before deep sleep

static rtc_relative_time_t s_idle_since = 0;

static const char* get_day_of_week_str(device_schedule_day_of_week_t day) {
    switch(day) {
        case SCHED_MONDAY: return "MON";
        case SCHED_TUESDAY: return "TUE";
        case SCHED_WEDNESDAY: return "WED";
        case SCHED_THURSDAY: return "THU";
        case SCHED_FRIDAY: return "FRI";
        case SCHED_SATURDAY: return "SAT";
        case SCHED_SUNDAY: return "SUN";
        default: return "UNK";
    }
}

static const char* get_schedule_type_str(device_schedule_type_t type) {
    switch(type) {
        case SCHED_NONE: return "NONE";
        case SCHED_SIMPLE: return "SIMPLE";
        default: return "UNKNOWN";
    }
}

static const char* get_take_effect_str(device_schedule_take_effect_t effect) {
    switch(effect) {
        case SCHED_IMMEDIATE: return "IMMEDIATE";
        case SCHED_NEXT_RELOAD: return "NEXT_RELOAD";
        default: return "UNKNOWN";
    }
}

static uint8_t calculate_schedule_length_days(const device_schedule_t* sched)
{
    if (!sched || sched->type != SCHED_SIMPLE) {
        return 0;
    }

    uint8_t max_day_of_week = 0;
    bool found_any = false;

    for (uint8_t i = 0; i < sched->schedule.simple_schedule.bin_count; i++) {
        const device_bin_schedule_t* bs = &sched->schedule.simple_schedule.bins[i];
        if (bs->day_of_week > max_day_of_week) {
            max_day_of_week = bs->day_of_week;
        }
        found_any = true;
    }

    if (!found_any) {
        return 0;
    }

    // Return max_day + 1 (if last day is Friday=4, schedule length is 5 days)
    return max_day_of_week + 1;
}

static void print_schedule(const device_schedule_t* sched) {
    if (!sched) return;

    ESP_LOGI(TAG, "--- Schedule Info ---");
    // .36s ensures it won't overflow if it lacks a null terminator
    ESP_LOGI(TAG, "ID: %.36s", sched->id);
    ESP_LOGI(TAG, "Type: %s", get_schedule_type_str(sched->type));
    ESP_LOGI(TAG, "Take Effect: %s", get_take_effect_str(sched->take_effect));
    ESP_LOGI(TAG, "Timezone IANA: %s", sched->timezone_iana);
    ESP_LOGI(TAG, "Timezone POSIX: %s", sched->timezone_posix);

    if (sched->type == SCHED_SIMPLE) {
        uint8_t count = sched->schedule.simple_schedule.bin_count;
        ESP_LOGI(TAG, "Active Bins Count: %d", count);
        
        for (uint8_t i = 0; i < count; i++) {
            const device_bin_schedule_t* bs = &sched->schedule.simple_schedule.bins[i];
            ESP_LOGI(TAG, "  Sched Bin %d -> Day: %s, Time: %02d:%02d", 
                     i, get_day_of_week_str(bs->day_of_week), bs->hour, bs->minute);
        }
    }
}

static void set_led_idle_task()
{
    device_error_flag_t flags = supervisor_get_error_flags();

    if (flags == DEVERR_NONE) {
        if (s_device_state.reload_state.stage == RELOAD_NONE) {

            int16_t blink_mask = 0;
            int16_t green_mask = 0;
            int16_t red_mask = 0;
            for (int i = 0; i < 14; i++) {
                bin_state_t* bs = &s_device_state.bins[i];
                if (bs->status == TAKE_NOW) {
                    blink_mask |= 1 << i;
                    green_mask |= 1 << i;
                } else if (bs->status == TAKEN) {
                    green_mask |= 1 << i;
                } else if (bs->status == MISSED) {
                    red_mask |= 1 << i;
                }
            }
            
            ledc_set_idle_task(LED_DEVICE_STATE, (led_task_param_t){
                .device_state = {
                    .red = red_mask,
                    .green = green_mask,
                    .blink_mask = blink_mask
                }
            });
        } else if (s_device_state.reload_state.stage == RELOAD_NEEDS_RELOAD) {
            ledc_set_idle_task(LED_BREATHE, (led_task_param_t) {
                        .blink = {
                            .red = LED_ALL_DOORS,
                            .green = LED_ALL_DOORS
                        }
                    });
        } else if (s_device_state.reload_state.stage == RELOAD_RELOADING) {
            ledc_set_idle_task(LED_DEVICE_STATE, (led_task_param_t) {
                .device_state = {
                    .red = s_device_state.reload_state.complete_mask & ~s_device_state.reload_state.progress,
                    .green = s_device_state.reload_state.complete_mask & s_device_state.reload_state.progress,
                    .blink_mask = s_device_state.reload_state.complete_mask & s_device_state.doors
                }
            });
        }
    } else {
        ledc_set_idle_task(LED_BREATHE, (led_task_param_t) {
            .blink = {
                .red = LED_ALL_DOORS,
                // Exclude some bins to indicate the issue to the user
                .green = LED_ALL_DOORS & ~((int)flags)
            }
        });
    }
}

static void update_state_from_runtime(device_state_t* state)
{
    state->error_flags = (int)supervisor_get_error_flags();
    state->battery = battery_get_state();
}

static esp_err_t update_device_state()
{
    esp_err_t err;

    // Mark updated at timestamp
    // Can fail if we can't get a valid time
    if ((err = app_rtc_get_utc_timestamp_ms(&s_device_state.modified_at)) != ESP_OK) {
        return ESP_ERR_INVALID_STATE;
    }

    update_state_from_runtime(&s_device_state);

    /* NVS Persistence */

    // Build persistent state struct
    device_persistent_state_t pers;

    // Ensure struct is empty
    memset(&pers, 0, sizeof(pers));

    // Copy fields
    pers.modified_at = s_device_state.modified_at;
    pers.synced_at = s_device_state.synced_at;
    pers.schedule = s_device_state.schedule; 
    pers.epoch_week = s_device_state.epoch_week;
    snprintf(pers.timezone_iana, sizeof(pers.timezone_iana), "%s", s_device_state.timezone_iana);
    snprintf(pers.timezone_posix, sizeof(pers.timezone_posix), "%s", s_device_state.timezone_posix);

    for (int i = 0; i < 14; i++) {
        pers.bins[i].status = s_device_state.bins[i].status;
        pers.bins[i].scheduled_time = s_device_state.bins[i].scheduled_time;
        pers.bins[i].event_time = s_device_state.bins[i].event_time;
        snprintf(pers.bins[i].schedule_id, sizeof(pers.bins[i].schedule_id), "%s", s_device_state.bins[i].schedule_id);
    }

    // Save state to NVS
    if ((err = devcfg_set_device_state(&pers)) != ESP_OK) {
        return err;
    }

    /* Update LEDs */
    set_led_idle_task();

    /* Notify supervisor of state change */
    return supervisor_submit_event(EVENT_STATE_CHANGED);
}

static bool should_schedule_bin(const bin_state_t* bin_state, time_t current_sec)
{
    bin_status_t status = bin_state->status;

    switch(status) {
        case DISABLED:
        case PENDING:
        case TAKE_NOW:
            // For bin statuses implicitly in the future, they should be updated unconditionally
            return true;
        default:
            // All other states could be in the past
            // In those cases, only schedule if in the future
            return bin_state->scheduled_time < 1 || bin_state->scheduled_time > current_sec;
    }
}

static time_t calculate_scheduled_time(const device_bin_schedule_t* bin_schedule, time_t epoch_week)
{
    if (!bin_schedule) {
        return (time_t)-1; 
    }

    // 1. Break down the arbitrary epoch week timestamp into local time components
    struct tm target_local_tm;
    localtime_r(&epoch_week, &target_local_tm); 

    // 2. Map the standard tm_wday (0=Sun, 1=Mon...) to your enum (0=Mon, 1=Tue... 6=Sun)
    int epoch_mapped_wday = (target_local_tm.tm_wday + 6) % 7;

    // 3. Calculate the day offset between the epoch's day and the scheduled day
    int days_diff = bin_schedule->day_of_week - epoch_mapped_wday;

    // 4. Construct the target local time for that specific schedule within the epoch week
    target_local_tm.tm_mday += days_diff; // mktime will handle month/year roll-overs automatically
    target_local_tm.tm_hour = bin_schedule->hour;
    target_local_tm.tm_min  = bin_schedule->minute;
    target_local_tm.tm_sec  = 0;
    
    // 5. Let mktime properly calculate Daylight Saving Time for the resulting date
    target_local_tm.tm_isdst = -1; 

    // 6. Convert the constructed local time back to an absolute UTC time_t
    return mktime(&target_local_tm);
}

static void schedule_bin(int bin_id, device_bin_schedule_t* bin_schedule,
        device_state_t* state, bool force)
{
    bin_state_t* bin_state = &state->bins[bin_id];

    // Check current time
    time_t current_sec = time(NULL);

    // Check if we should update this bin
    if (should_schedule_bin(bin_state, current_sec) || force) {
        if (bin_schedule != NULL) {
            // Schedule assigned to bin
            bin_state->scheduled_time = calculate_scheduled_time(bin_schedule, state->epoch_week);

            if (bin_state->scheduled_time > current_sec) {
                // If the new scheduled time is in the future, set it to pending
                bin_state->status = PENDING;
            } else {
                // Otherwise, we just updated a bin scheduled in the past
                // So we don't know what state it's in
                bin_state->status = NO_RECORD;
            }
            
        } else {
            // No schedule assigned to bin -> disable it 
            bin_state->status = DISABLED;
            bin_state->scheduled_time = -1;
        }
        snprintf(bin_state->schedule_id, sizeof(bin_state->schedule_id), "%s", state->schedule.id);
    }
}

static device_schedule_validation_t apply_schedule(const device_schedule_t* sched, device_state_t* state, bool force)
{
    // We only support simple schedules right now
    if (sched->type != SCHED_SIMPLE) {
        return SCHED_ERR_UNSUPPORTED_TYPE;
    }

    if (sched->schedule.simple_schedule.bin_count > 14) {
        return SCHED_ERR_TOO_MANY_PERIODS;
    }

    // Copy schedule into new state
    memcpy(&state->schedule, sched, sizeof(device_schedule_t));

    // Count periods in each day of week
    uint8_t dow_ctr[7] = {0};
    
    // Assign periods to bins
    device_bin_schedule_t bins[14] = {};

    for (uint8_t i = 0; i < sched->schedule.simple_schedule.bin_count; i++) {
        const device_bin_schedule_t* bs = &sched->schedule.simple_schedule.bins[i];

        if (dow_ctr[bs->day_of_week] >= 2) {
            return SCHED_ERR_TOO_MANY_PERIODS_IN_DAY;
        }
   
        bins[(bs->day_of_week * 2) + dow_ctr[bs->day_of_week]] = *bs;

        dow_ctr[bs->day_of_week]++;
    }

    if (sched->take_effect == SCHED_IMMEDIATE || force) {
        // Ensure we have a valid epoch week to work with
        if (state->epoch_week < 1) {
            ESP_ERROR_CHECK(app_rtc_get_current_epoch_week(&state->epoch_week));
        }

        
        // Now loop through each day of week and assign to state
        for (int i = 0; i < 7; i++) {
            uint8_t periods_in_day = dow_ctr[i];
            if (periods_in_day == 0) {
                // Nothing scheduled on this day!
                schedule_bin(i * 2, NULL, state, force);
                schedule_bin(i * 2 + 1, NULL, state, force);
            } else if(periods_in_day == 1) {
                schedule_bin(i * 2 + 1, &bins[i * 2], state, force);
                schedule_bin(i * 2 , NULL, state, force);
            } else if(periods_in_day == 2) {
                schedule_bin(i * 2 + 1, &bins[i * 2], state, force);
                schedule_bin(i * 2, &bins[i * 2 + 1], state, force);
            } else {
                return SCHED_ERR_TOO_MANY_PERIODS_IN_DAY;
            }
        }
    }

    return SCHED_VALID;
}


static void process_schedule_delta(const device_schedule_t* sched)
{
    ESP_LOGI(TAG, "========= Schedule Delta =========");
    print_schedule(sched);

    // Guard: skip if we already have this exact schedule applied
    if (sched->id[0] != '\0' && s_device_state.schedule.id[0] != '\0' &&
        strcmp(sched->id, s_device_state.schedule.id) == 0) {
        ESP_LOGI(TAG, "Schedule ID %s already applied, skipping delta", sched->id);
        return;
    }

    device_state_t state_copy;
    memcpy(&state_copy, &s_device_state, sizeof(device_state_t));

    // Attempt to apply schedule to copied state
    device_schedule_validation_t validation = apply_schedule(sched, &state_copy, false);
    if (validation == SCHED_VALID) {
        // Schedule valid!
        
        // Copy updated state from the applied copy 
        memcpy(&s_device_state, &state_copy, sizeof(device_state_t));

        // Calculate and store the schedule length
        s_device_state.schedule_length_days = calculate_schedule_length_days(&s_device_state.schedule);
        ESP_LOGI(TAG, "Schedule length calculated: %d days", s_device_state.schedule_length_days);

        // Clear no-schedule error now that a valid schedule has been applied
        supervisor_clear_error(DEVERR_NO_SCHEDULE);

        // Apply timezone from the new schedule to device state and the system.
        // POSIX format alone is sufficient to configure the system timezone via setenv("TZ",...).
        // IANA is stored alongside it for state reporting only.
        // Always apply immediately if no timezone is currently set (DEVERR_NO_TIMEZONE asserted),
        // otherwise follow the schedule's take_effect rule.
        bool no_timezone = (supervisor_get_error_flags() & DEVERR_NO_TIMEZONE) != 0;
        bool apply_tz_now = no_timezone || (sched->take_effect == SCHED_IMMEDIATE);

        if (sched->timezone_posix[0] != '\0' && apply_tz_now) {
            snprintf(s_device_state.timezone_posix, sizeof(s_device_state.timezone_posix),
                     "%s", sched->timezone_posix);
            snprintf(s_device_state.timezone_iana, sizeof(s_device_state.timezone_iana),
                     "%s", sched->timezone_iana);
            app_rtc_set_timezone(s_device_state.timezone_posix);
            supervisor_clear_error(DEVERR_NO_TIMEZONE);
            ESP_LOGI(TAG, "Timezone applied: IANA=%s POSIX=%s",
                     s_device_state.timezone_iana, s_device_state.timezone_posix);
        }

        ESP_ERROR_CHECK(update_device_state());
        ESP_ERROR_CHECK(shadow_state_report_schedule(&s_device_state.schedule));
        /* Flush full state to NVS on schedule change — schedule must survive power loss */
        devcfg_flush_state_to_nvs();
        return;
    }

    ESP_LOGW(TAG, "Schedule %s rejected: %d", sched->id, validation);

    // Update current schedule with rejection info
    snprintf(s_device_state.schedule.rejected_id, sizeof(s_device_state.schedule.rejected_id), "%s", sched->id);
    s_device_state.schedule.rejected_reason = validation;
}

static void print_state(const device_state_t* state) {
    if (!state) return;

    ESP_LOGI(TAG, "=== Device State ===");
    ESP_LOGI(TAG, "Modified At: %lld (Unix timestamp in ms)", state->modified_at);
    ESP_LOGI(TAG, "Battery: %s", battery_status_str(state->battery));
    ESP_LOGI(TAG, "Error Flags: 0x%04X", state->error_flags);
    ESP_LOGI(TAG, "Doors Bitfield: 0x%04X", state->doors);
    ESP_LOGI(TAG, "Epoch week: %lld (Unix timestamp UTC)", state->epoch_week);

    ESP_LOGI(TAG, "--- Bin States ---");
    for (int i = 0; i < 14; i++) {
        const bin_state_t* bin = &state->bins[i];
        
        // Using %d for bin_status_t assuming it's an enum. Adjust if it's a struct.
        // Using %.36s for schedule_id to safely print up to 36 UUID chars (SCHEDULE_ID_SIZE = 37 including null).
        ESP_LOGI(TAG, "  Bin %2d | Status: %d | Sched: %lld | Event: %lld | Open: %lld | Close: %lld | SchedID: %.36s",
                 i,
                 (int)bin->status, 
                 (long long)bin->scheduled_time, 
                 (long long)bin->event_time, 
                 (long long)bin->opened_at, 
                 (long long)bin->closed_at,
                 bin->schedule_id[0] != '\0' ? bin->schedule_id : "N/A");
    }

    print_schedule(&state->schedule);
    ESP_LOGI(TAG, "====================");
}

static void start_reload()
{
    // Create temporary state object
    // This state will be applied upon completion
    device_state_t *future_state = (device_state_t *) malloc(sizeof(device_state_t));
    if (future_state == NULL) {
        ESP_LOGE(TAG, "Failed to allocate memory for future_state, aborting reload");
        return;
    }

    memcpy(future_state, &s_device_state, sizeof(device_state_t));

    // Calculate new epoch_week from current time
    time_t new_epoch_week;
    if (app_rtc_get_current_epoch_week(&new_epoch_week) != ESP_OK) {
        ESP_LOGE(TAG, "Failed to get current epoch week, aborting reload");
        free(future_state);
        return;
    }

    time_t stored_epoch_week = future_state->epoch_week;

    // Preserve a stored future epoch_week, advance only when the stored value
    // matches the current epoch_week, and otherwise fall back to the current week.
    if (stored_epoch_week == new_epoch_week) {
        // Calculate the number of seconds to add (schedule_length_days * 86400)
        time_t schedule_length_seconds = (time_t)s_device_state.schedule_length_days * 86400;
        new_epoch_week += schedule_length_seconds;
        ESP_LOGI(TAG, "Epoch week was current week, advancing by %d days", s_device_state.schedule_length_days);
    } else if (stored_epoch_week > new_epoch_week) {
        new_epoch_week = stored_epoch_week;
        ESP_LOGI(TAG, "Epoch week is already in the future, keeping stored value");
    } else {
        ESP_LOGI(TAG, "Epoch week was stale, using newly calculated week");
    }

    // Update future_state with the selected epoch_week for schedule calculation
    future_state->epoch_week = new_epoch_week;
    ESP_LOGI(TAG, "Reload: epoch_week set to %lld", (long long)new_epoch_week);

    // Apply current schedule to the future state
    int rc = apply_schedule(&s_device_state.schedule, future_state, true);
    if (rc != 0) {
        ESP_LOGE(TAG, "apply_schedule failed (%d), aborting reload", rc);
        if (s_device_state.schedule.type == SCHED_NONE) {
            supervisor_assert_error(DEVERR_NO_SCHEDULE);
        }
        free(future_state);
        return;
    }

    // Set internal state only after successful preparation of future_state
    s_device_state.reload_state.stage = RELOAD_RELOADING;
    s_device_state.reload_state.progress = 0;
    s_device_state.reload_state.complete_mask = 0;
    s_device_state.reload_state.start_time = app_rtc_get_relative_timestamp();
    s_device_state.reload_state.future_state = future_state;

    // Calculate bitmask required for reload to be complete
    for (int i = 0; i < 14; i++) {
        bin_state_t *bs = &future_state->bins[i];
        ESP_LOGI(TAG, "Bin %d sched %lld %d", i, bs->scheduled_time, bs->status);
        if (bs->status == PENDING || bs->status == TAKE_NOW) {
            s_device_state.reload_state.complete_mask |= (1 << i);
        }
    }

    ESP_LOGI(TAG, "Reload started, required mask: %x", s_device_state.reload_state.complete_mask);

    // Ensure LEDs are configured for reload
    set_led_idle_task();
}

static void cleanup_reload()
{
    if (s_device_state.reload_state.future_state != NULL) {
        free(s_device_state.reload_state.future_state);
        s_device_state.reload_state.future_state = NULL;
    }
}

static void reload_complete()
{
    s_device_state.reload_state.stage = RELOAD_NONE;
    
    // Copy the calculated epoch_week and bin states from future_state
    s_device_state.epoch_week = s_device_state.reload_state.future_state->epoch_week;
    memcpy(&s_device_state.bins, &s_device_state.reload_state.future_state->bins,
         sizeof(s_device_state.bins));
    
    cleanup_reload();
    ESP_LOGI(TAG, "Reload complete: epoch_week updated to %lld", s_device_state.epoch_week);

    // Ensure the new state is persisted
    ESP_ERROR_CHECK(devcfg_flush_state_to_nvs());

    ESP_ERROR_CHECK(update_device_state());
}

static void check_state_transitions()
{
    bool changed = false;

    if (!app_rtc_time_synced()) {
        supervisor_assert_error(DEVERR_NO_RTC_TIME);
        return;
    }

    if (supervisor_get_error_flags() != DEVERR_NONE) {
        // Device is in failsafe mode -- lock out state changes
        return;
    }

    time_t current_sec = time(NULL);
    bool has_scheduled_in_future = false;

    for (int i = 0; i < 14; i++) {
        bin_state_t* bin_state = &s_device_state.bins[i];

        // If the bin has a scheduled time set
        if (bin_state->scheduled_time > 0) { 

            // If the scheduled time is in the future, mark that there are still future scheduled 
            if (bin_state->scheduled_time > (current_sec + MISSED_THRESHOLD_SEC) && !has_scheduled_in_future) {
                has_scheduled_in_future = true;
            }

            // Positive if the scheduled time has passed (past)
            // Negative if the scheduled time is yet to come (future)
            int64_t elapsed_sec = current_sec - bin_state->scheduled_time;

            if (bin_state->status == PENDING) {
                // If the scheduled time has passed or is exactly now
                if (elapsed_sec >= 0) {
                    
                    if (elapsed_sec <= MISSED_THRESHOLD_SEC) {
                        // We are within the acceptable window to take the medication
                        bin_state->status = TAKE_NOW;
                        ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_BIN_TAKE_NOW, (intptr_t)i, 100));
                    } else {
                        // We woke up/checked and the entire window was already missed.
                        // Setting to NO_RECORD to indicate a gap in logging.
                        bin_state->status = NO_RECORD;
                    }
                    changed = true;
                }
            } else if (bin_state->status == TAKE_NOW) {
                // If the bin is currently prompting the user to take it
                if (elapsed_sec > MISSED_THRESHOLD_SEC) {
                    // ... and we've now passed the missed threshold
                    bin_state->status = MISSED;
                    ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_BIN_MISSED, (intptr_t)i, 100));
                    changed = true;
                }
            }
        }
    }

    if (!has_scheduled_in_future) {
        if (s_device_state.reload_state.stage == RELOAD_NONE) {
            s_device_state.reload_state.stage = RELOAD_NEEDS_RELOAD;
            changed = true;
        }
    }

    if (changed) {
        ESP_ERROR_CHECK(update_device_state());
        ESP_ERROR_CHECK(devcfg_flush_state_to_nvs());
    }
}


static void load_state()
{
    esp_err_t err;
    device_persistent_state_t pers;

    // Ensure current state is empty
    memset(&s_device_state, 0, sizeof(s_device_state));

    if ((err = devcfg_get_device_state(&pers)) == ESP_OK) {
        // Copy fields
        s_device_state.modified_at = pers.modified_at;
        s_device_state.synced_at   = pers.synced_at;
        s_device_state.schedule = pers.schedule;
        s_device_state.epoch_week = pers.epoch_week;
        snprintf(s_device_state.timezone_iana, sizeof(s_device_state.timezone_iana), "%s", pers.timezone_iana);
        snprintf(s_device_state.timezone_posix, sizeof(s_device_state.timezone_posix), "%s", pers.timezone_posix);

        // Copy bin state
        for (uint8_t i = 0; i < 14; i++) {
            s_device_state.bins[i].status = pers.bins[i].status;
            memcpy(s_device_state.bins[i].schedule_id, pers.bins[i].schedule_id, SCHEDULE_ID_SIZE);
            s_device_state.bins[i].scheduled_time = pers.bins[i].scheduled_time;
            s_device_state.bins[i].event_time = pers.bins[i].event_time;
        }

        // Recalculate schedule_length_days from loaded schedule (derived value, not persisted)
        s_device_state.schedule_length_days = calculate_schedule_length_days(&s_device_state.schedule);

        // Assert error if no schedule has been configured
        if (s_device_state.schedule.type == SCHED_NONE) {
            ESP_LOGW(TAG, "No schedule configured");
            supervisor_assert_error(DEVERR_NO_SCHEDULE);
        }

        // Apply persisted timezone as the system timezone; assert error if none is set
        if (s_device_state.timezone_posix[0] != '\0') {
            app_rtc_set_timezone(s_device_state.timezone_posix);
        } else {
            ESP_LOGW(TAG, "No timezone configured");
            supervisor_assert_error(DEVERR_NO_TIMEZONE);
        }
    } else {
        // Failed to load state, trigger failsafe
        supervisor_assert_error(DEVERR_STATE_CORRUPTED);
    }

    // Print loaded state
    print_state(&s_device_state);

    // Check for state changes on load
    check_state_transitions();
}

static bin_state_t* get_next_scheduled_bin(time_t after)
{
    bin_state_t* closest_st = NULL;

    for (int i = 0; i < 14; i++) {
        bin_state_t* bin_state = &s_device_state.bins[i];

        // Check if the bin is scheduled in the future
        if (bin_state->scheduled_time > after) {
            // If it's the first one we've found, or if it's sooner than our current closest
            if (closest_st == NULL || bin_state->scheduled_time < closest_st->scheduled_time) {
                closest_st = bin_state;
            }
        }
    }
    
    return closest_st;
}

static bin_state_t* get_prev_scheduled_bin(time_t before) 
{
    bin_state_t* closest_st = NULL;

    for (int i = 0; i < 14; i++) {
        bin_state_t* bin_state = &s_device_state.bins[i];

        // Check if the bin was scheduled in the past. 
        // We enforce > 0 to filter out unprogrammed bins.
        if (bin_state->scheduled_time > 0 && bin_state->scheduled_time < before) {
            // If it's the first one we've found, or if it's more recent than our current closest
            if (closest_st == NULL || bin_state->scheduled_time > closest_st->scheduled_time) {
                closest_st = bin_state;
            }
        }
    }
    
    return closest_st;
}

static bool should_mark_taken(bin_state_t* bin_state)
{

    time_t current_sec;
    time(&current_sec);

    if (current_sec < 1 || !app_rtc_time_synced()) {
        ESP_LOGW(TAG, "Time not valid!");
        return false;
    }

    if (bin_state->status == TAKE_NOW) {
        return true;
    } else if (bin_state->status == MISSED) {
        // Accept missed doses only if taken before the next scheduled dose
        bin_state_t* next_bin = get_next_scheduled_bin(bin_state->scheduled_time);
        if (!next_bin) {
            // No future dose scheduled; keep previous behavior and accept
            return true;
        } else {
            return current_sec < next_bin->scheduled_time;
        }
    } else if (bin_state->status == PENDING) {
        // Accept early doses only if taken after the previously scheduled dose
        bin_state_t* prev_bin = get_prev_scheduled_bin(bin_state->scheduled_time);
        if (!prev_bin) {
            // No previous dose scheduled; keep previous behavior and accept
            return true;
        } else {
            return current_sec > prev_bin->scheduled_time;
        }
    }

    return false;
}

static void door_light_effect(int door_id, bool open, bool correct)
{
    led_task_param_t fw_param = {0};
    fw_param.firework.red = correct ? 0x0000 : LED_ALL_DOORS;       
    fw_param.firework.green = LED_ALL_DOORS; 
    fw_param.firework.center_bin = (int)door_id;      
    fw_param.firework.implode = !open;

    ledc_set_task(LED_FIREWORK, fw_param, 500);
}

static void handle_door_open(int door_id)
{
    bin_state_t* bin_state = &s_device_state.bins[door_id];
    bool taken_event = should_mark_taken(bin_state);

    door_light_effect(door_id, true, taken_event);

    // Update state
    s_device_state.doors |= 1 << door_id;
    bin_state->opened_at = app_rtc_get_relative_timestamp();

    bin_state->flags |= BIN_FLAG_OPEN;
    /* Clear the left-open notification flag so the tick can fire again if the
     * door is closed and re-opened. */
    bin_state->flags &= ~BIN_FLAG_LEFT_OPEN_NOTIFIED;
    if (taken_event) {
        bin_state->flags |= BIN_FLAG_ON_TIME;
    }

    update_device_state();
}

static void handle_door_close(int door_id)
{
    
    bin_state_t* bin_state = &s_device_state.bins[door_id];
    bool taken_event = should_mark_taken(bin_state);
    
    door_light_effect(door_id, false, taken_event);
    
    // Update flags
    s_device_state.doors &= ~(1 << door_id);
    bin_state->closed_at = app_rtc_get_relative_timestamp();

    bin_state->flags &= ~BIN_FLAG_OPEN;
    bin_state->flags &= ~BIN_FLAG_ON_TIME;
    bin_state->flags &= ~BIN_FLAG_LEFT_OPEN_NOTIFIED;

    if (taken_event) {
        // Fire event
        ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_BIN_TAKEN, (intptr_t)door_id, 100));
    }

    update_device_state();
}

static void handle_reload_fsm(const supervisor_event_t* event)
{
    switch (s_device_state.reload_state.stage) {
        case RELOAD_NONE:
            break;
        case RELOAD_NEEDS_RELOAD:
            if (event->id == EVENT_DOOR_OPENED) {
                // Start reload
                start_reload();
            }
            break;
        case RELOAD_RELOADING:
            if (event->id == EVENT_DOOR_CLOSED) {
                int door_id = (int)event->payload;
                s_device_state.reload_state.progress |= (1 << door_id);

                if ((s_device_state.reload_state.progress & s_device_state.reload_state.complete_mask) == s_device_state.reload_state.complete_mask) {
                    // Reload complete!
                    supervisor_submit_event(EVENT_RELOAD_COMPLETE);
                    ESP_LOGI(TAG, "Reload complete");
                }

                set_led_idle_task();
            } else if (event->id == EVENT_RELOAD_TIMEOUT) {
                s_device_state.reload_state.stage = RELOAD_NEEDS_RELOAD;
                cleanup_reload();

                // Failed effect -- blink all red for 6 seconds
                ledc_set_task(LED_BLINK, (led_task_param_t) {
                    .breathe = {
                        .red = LED_ALL_DOORS,
                        .green = 0x0000
                    }
                }, 6000);
            } else if (event->id == EVENT_RELOAD_COMPLETE) {
                // Reload complete!
                reload_complete();

                ledc_set_task(LED_BLINK, (led_task_param_t) {
                    .breathe = {
                        .red = 0x0000,
                        .green = LED_ALL_DOORS
                    }
                }, 6000);
            }
            break;
    }
}

static void handle_device_event_bin(device_event_type_t event_type, int bin_id)
{
    rtc_utc_timestamp_ms ts = 0;

    if (app_rtc_get_utc_timestamp_ms(&ts) != ESP_OK) {
        /* Cannot timestamp the event: enter failsafe and discard. */
        supervisor_assert_error(DEVERR_NO_RTC_TIME);
        return;
    }

    /* Push to outbox unconditionally, regardless of MQTT connection state. */
    esp_err_t push_err = event_outbox_push(ts, event_type, bin_id, 0);
    if (push_err == ESP_ERR_NO_MEM) {
        supervisor_assert_error(DEVERR_OUTBOX_FULL);
    }

    device_event_t devev = {
        .timestamp = ts,
        .event_type = event_type,
        .bin_id = bin_id
    };

    switch (devev.event_type) {
        case DEVEVT_DOOR_OPENED:
            handle_door_open(devev.bin_id);
            break;
        case DEVEVT_DOOR_CLOSED:
            handle_door_close(devev.bin_id);
            break;
        case DEVEVT_DOOR_LEFT_OPEN:
            /* Door was left open too long; update state to trigger drain and persist */
            ESP_ERROR_CHECK(update_device_state());
            break;
        case DEVEVT_TAKEN:
            s_device_state.bins[devev.bin_id].status = TAKEN;
            s_device_state.bins[devev.bin_id].event_time = devev.timestamp;
            ESP_ERROR_CHECK(update_device_state());
            /* Flush full state to NVS on TAKEN — pill confirmed, must survive power loss */
            devcfg_flush_state_to_nvs();
            break;

        default:
            break;
    }
}

static void handle_device_event_nobin(device_event_type_t event_type)
{
    handle_device_event_bin(event_type, EVENT_OUTBOX_BIN_ID_NONE);
}

static void handle_device_event(const supervisor_event_t* ev)
{
    switch (ev->id) {
        case EVENT_DOOR_OPENED:
            handle_device_event_bin(DEVEVT_DOOR_OPENED, (int)ev->payload);
            break;
        case EVENT_DOOR_CLOSED:
            handle_device_event_bin(DEVEVT_DOOR_CLOSED, (int)ev->payload);
            break;
        case EVENT_DOOR_LEFT_OPEN:
            handle_device_event_bin(DEVEVT_DOOR_LEFT_OPEN, (int)ev->payload);
            break;
        case EVENT_BIN_TAKEN:
            handle_device_event_bin(DEVEVT_TAKEN, (int)ev->payload);
            break;
        case EVENT_BIN_MISSED:
            handle_device_event_bin(DEVEVT_MISSED, (int)ev->payload);
            break;
        case EVENT_BIN_TAKE_NOW:
            handle_device_event_bin(DEVEVT_TAKE_NOW, (int)ev->payload);
            break;
        case EVENT_RELOAD_START:
            handle_device_event_nobin(DEVEVT_RELOAD_START); 
            break;
        case EVENT_RELOAD_COMPLETE:
            handle_device_event_nobin(DEVEVT_RELOAD_END);
            break; 
        case EVENT_RELOAD_TIMEOUT:
            handle_device_event_nobin(DEVEVT_ACTION_TIMEOUT);
            break; 
        default:
            break;
    }
}

static bool supervisor_is_device_idle()
{
    if (s_state != STATE_OPERATIONAL) return false;
    if (s_device_state.doors != 0) return false;
    if (s_device_state.reload_state.stage != RELOAD_NONE) return false;
    for (int i = 0; i < DEVICE_NUM_BINS; i++) {
        if (s_device_state.bins[i].status == TAKE_NOW) return false;
    }
    return true;
}

void supervisor_operation_init()
{
    s_state = STATE_INIT;
    load_state();

    // Mark this firmware partition as valid — enables bootloader rollback if the
    // new firmware crashes before reaching this point on the next boot.
    esp_ota_mark_app_valid_cancel_rollback();

    // Init shadow state and OTA module
    shadow_state_init();
    ota_init();

    // Network already started at this point
    s_state = STATE_CONNECTING_NETIF;

    // Mark as initialized
    atomic_store(&s_init, true);
}

bool supervisor_operation_is_initialized()
{
    return atomic_load(&s_init);
}

void supervisor_operation_event(const supervisor_event_t* event)
{
    // Unconditional events 
    if (event->id == EVENT_ERROR_CONDITION) {
        ESP_LOGW(TAG, "Received error condition: 0x%x", (int)event->payload);
        // Attempt to update internal state
        update_device_state();
    } else if(event->id == EVENT_ERROR_CLEARED) {
        ESP_LOGI(TAG, "Error condition cleared: 0x%x", (int)event->payload);
        update_device_state();
    } else if(event->id == EVENT_TIME_SYNCED) {
        // Clear time sync error condition
        supervisor_clear_error(DEVERR_NO_RTC_TIME);
    } else if (event->id == EVENT_LED_EFFECT_COMPLETE) {
        set_led_idle_task();
    } else if (event->id == EVENT_BATTERY_CHANGE) {
        battery_state_t new_battery_state = battery_get_state(); 

        // LED effect (blink green for 2s) when charging starts 
        if (s_device_state.battery.charge_state != BATTERY_CHARGE_CHARGING && new_battery_state.charge_state == BATTERY_CHARGE_CHARGING) {
            ledc_set_task(LED_BLINK, (led_task_param_t) {
                        .blink = {
                            .red = 0,
                            .green = LED_ALL_DOORS
                        }
                    }, 2000);
        }

        s_device_state.battery = new_battery_state;
        ESP_LOGI(TAG, "New battery state: %s", battery_status_str(s_device_state.battery));
        update_device_state();
    } else if (event->id == EVENT_OTA_JOB_RECEIVED) {
        ota_job_t* job = (ota_job_t*)(intptr_t)event->payload;
        if (!job) {
            ESP_LOGE(TAG, "EVENT_OTA_JOB_RECEIVED with NULL payload");
        } else if (s_pending_deferred == DEFERRED_OTA || s_state == STATE_OTA) {
            /* Already processing an OTA job — discard duplicate */
            ESP_LOGD(TAG, "OTA job %s ignored — already processing a job", job->job_id);
            free(job);
        } else {
            /* Accept the job into OTA module state */
            ota_accept_job(job);

            /* If the device is already running the target version, reject immediately */
            const char* current_version = esp_app_get_description()->version;
            if (strcmp(job->version, current_version) == 0) {
                ESP_LOGI(TAG, "OTA job %s targets current version %s — rejecting",
                         job->job_id, current_version);
                ota_reject();
            } else {
                ESP_LOGI(TAG, "OTA job %s received, deferring execution until device is idle",
                         job->job_id);
                s_pending_deferred = DEFERRED_OTA;
            }
            free(job);
        }
    } else if (event->id == EVENT_OTA_COMPLETE) {
        s_pending_deferred = DEFERRED_NONE;
        ota_on_complete();
        /* State stays STATE_OTA; device will reboot shortly */
        supervisor_submit_event(EVENT_REBOOT_REQUESTED);
    } else if (event->id == EVENT_OTA_FAILED) {
        s_pending_deferred = DEFERRED_NONE;
        ota_on_failed();
        s_state = STATE_OPERATIONAL;
        ESP_LOGI(TAG, "OTA failed — returning to OPERATIONAL state");
    }

    // Handle medication reload FSM 
    handle_reload_fsm(event);

    // Handle device events
    handle_device_event(event);

    // Bootstrap events
    switch (s_state) {
        case STATE_CONNECTING_NETIF:
            if (event->id == EVENT_NETIF_CONNECTED) {
                s_state = STATE_SYNCING_TIME;
                app_rtc_sync();
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                ESP_LOGW(TAG, "Failed to connect to network. Retrying...");
                network_reconnect();
            }
            break;
        case STATE_SYNCING_TIME:
            if (event->id == EVENT_TIME_SYNCED) {
                mqtt_init();
                s_state = STATE_CONNECTING_MQTT;
            }
            break;
        case STATE_CONNECTING_MQTT:
            if (event->id == EVENT_MQTT_CONNECTED) {
                app_rtc_get_utc_timestamp_ms(&s_device_state.synced_at);
                mqtt_publish_device_state(&s_device_state);
                shadow_state_on_connect();
                ota_on_connect();
                /* Drain any events that accumulated before MQTT connected. */
                event_outbox_drain();
                s_state = STATE_MQTT_CONNECTED;
            }
            break;
        case STATE_MQTT_CONNECTED:
            if (event->id == EVENT_SHADOW_READY) {
                shadow_state_report_schedule(&s_device_state.schedule);
                s_state = STATE_OPERATIONAL;
            }
            break;
        case STATE_OPERATIONAL:
            if (event->id == EVENT_SCHEDULE_DELTA_RECEIVED) {
                device_schedule_t* sched = (device_schedule_t*)event->payload;
                process_schedule_delta(sched);
                free(sched);

                // Start lighting effect to indicate schedule updated
                ledc_set_task(LED_BREATHE, (led_task_param_t) {
                    .breathe = {
                        .red = 0x0000,
                        .green = LED_ALL_DOORS
                    }
                }, 6000);
            } else if (event->id == EVENT_STATE_CHANGED) {
                print_state(&s_device_state);
                app_rtc_get_utc_timestamp_ms(&s_device_state.synced_at);
                ESP_ERROR_CHECK(mqtt_publish_device_state(&s_device_state));
                /* Drain any newly pushed outbox events. */
                event_outbox_drain();
            }
#if CONFIG_FIRMWARE_ENGINEERING
            else if (event->id == EVENT_RESET_PENDING_BINS) {
                // Reset future-dated bins to PENDING for re-testing
                ESP_LOGI(TAG, "[ENGINEERING] Resetting pending bins from web interface");
                supervisor_operation_reset_pending_bins();
            }
#endif // CONFIG_FIRMWARE_ENGINEERING
            break;
        case STATE_OTA:
            /* OTA download is in progress in the worker task.
             * Do not process operational events; wait for EVENT_OTA_COMPLETE
             * or EVENT_OTA_FAILED to arrive from the worker task. */
            break;
        default:
            ESP_LOGW(TAG, "Unhandled state: %d", s_state);
            break;
    }

    // Unconditional tasks to perform after state-specific tasks are complete
    if (event->id == EVENT_NETIF_DISCONNECTED) {
        // Attempt to reconnect to Wi-Fi
        ESP_LOGW(TAG, "Disconnected from Wi-Fi, reconnecting...");
        s_state = STATE_CONNECTING_NETIF;
        network_reconnect();
    } else if (event->id == EVENT_MQTT_DISCONNECTED) {
        ESP_LOGW(TAG, "Disconnected from MQTT");
        /* Reset all in-flight packet IDs so events are republished on reconnect. */
        event_outbox_reset_inflight();
        /* Don't overwrite STATE_OTA — the download runs over HTTP independently
         * of MQTT.  The MQTT client will reconnect on its own; when it does,
         * EVENT_MQTT_CONNECTED will be ignored because s_state != STATE_CONNECTING_MQTT. */
        if (s_state != STATE_OTA) {
            s_state = STATE_CONNECTING_MQTT;
        }
    } else if (event->id == EVENT_MQTT_PUBACK) {
        /* MQTT QoS-1 acknowledgement: mark the entry delivered and drain. */
        int msg_id = (int)(intptr_t)event->payload;
        if (event_outbox_ack(msg_id) == ESP_OK) {
            event_outbox_drain();
        }
    }
}

void supervisor_operation_tick()
{
    /* While OTA is in progress, skip all operational tick work — the download
     * runs in the worker task and will post EVENT_OTA_COMPLETE or
     * EVENT_OTA_FAILED when done. */
    if (s_state == STATE_OTA) {
        return;
    }

    // Check reload timeout
    if (s_device_state.reload_state.stage == RELOAD_RELOADING) {
        int64_t dur = app_rtc_calc_duration_ms(s_device_state.reload_state.start_time, 
            app_rtc_get_relative_timestamp());
        if (dur > RELOAD_TIMEOUT_MS) {
            ESP_ERROR_CHECK(supervisor_submit_event(EVENT_RELOAD_TIMEOUT));
        }
    }

    /* Check for doors that have been left open past the threshold. */
    rtc_relative_time_t now = app_rtc_get_relative_timestamp();
    for (int i = 0; i < DEVICE_NUM_BINS; i++) {
        bin_state_t* bin = &s_device_state.bins[i];
        if ((bin->flags & BIN_FLAG_OPEN) &&
            !(bin->flags & BIN_FLAG_LEFT_OPEN_NOTIFIED) &&
            bin->opened_at > 0) {
            int64_t dur = app_rtc_calc_duration_ms(bin->opened_at, now);
            if (dur >= DOOR_LEFT_OPEN_TIMEOUT_MS) {
                ESP_LOGI(TAG, "Door %d left open for %lld ms", i, dur);
                esp_err_t err = supervisor_submit_event_block(EVENT_DOOR_LEFT_OPEN, (intptr_t)i, 0);
                if (err == ESP_OK || err == ESP_ERR_NO_MEM) {
                    /* Mark notified even on queue-full: avoids flooding the log
                     * on every tick.  The event will fire again after door re-open. */
                    bin->flags |= BIN_FLAG_LEFT_OPEN_NOTIFIED;
                    if (err == ESP_ERR_NO_MEM) {
                        ESP_LOGW(TAG, "Dropping EVENT_DOOR_LEFT_OPEN for door %d: supervisor queue full", i);
                    }
                }
            }
        }
    }

    check_state_transitions();
    set_led_idle_task();

    /* Maintain event outbox: persist entries older than 60 s. */
    event_outbox_tick();

    /* Clear DEVERR_OUTBOX_FULL once the queue drops below capacity. */
    if ((supervisor_get_error_flags() & DEVERR_OUTBOX_FULL) && !event_outbox_is_full()) {
        supervisor_clear_error(DEVERR_OUTBOX_FULL);
    }

    /* Execute any pending deferred action when the device is idle. */
    if (s_pending_deferred != DEFERRED_NONE && supervisor_is_device_idle()) {
        deferred_action_t action = s_pending_deferred;
        s_pending_deferred = DEFERRED_NONE;
        if (action == DEFERRED_OTA) {
            s_state = STATE_OTA;
            ota_execute();
        }
    }

    /* Check for overdue sync */
    rtc_utc_timestamp_ms current_utc_ms;
    if (app_rtc_get_utc_timestamp_ms(&current_utc_ms) != ESP_OK) {
        /* Cannot get current time: enter failsafe and skip sync check. */
        supervisor_assert_error(DEVERR_NO_RTC_TIME);
    } else {
        int64_t diff = current_utc_ms - s_device_state.synced_at;

        if (diff >= 300000) {
            ESP_LOGI(TAG, "Last sync was %lld ms ago, syncing", diff);
            ESP_ERROR_CHECK(update_device_state());
        }
    }



    /* Deep sleep idle timeout: enter sleep after 1 minute of OPERATIONAL idle. */
#if !CONFIG_EMULATOR_MODE
/* Disable deep sleep for now to avoid issues with development and testing; will re-enable in a future PR after testing on hardware.
    if (s_state == STATE_OPERATIONAL) {
        if (supervisor_is_device_idle()) {
            if (s_idle_since == 0) {
                s_idle_since = app_rtc_get_relative_timestamp();
            } else {
                int64_t idle_ms = app_rtc_calc_duration_ms(s_idle_since, app_rtc_get_relative_timestamp());
                if (idle_ms >= IDLE_SLEEP_TIMEOUT_MS) {
                    ESP_LOGI(TAG, "Device idle for %lld ms — requesting deep sleep", idle_ms);
                    ESP_ERROR_CHECK(supervisor_submit_event(EVENT_DEEP_SLEEP_REQUESTED));
                }
            }
        } else {
            s_idle_since = 0;
        }
    }
        */
#endif
}

esp_err_t supervisor_operation_get_schedule(device_schedule_t* sched)
{
    if (!supervisor_operation_is_initialized()) {
        return ESP_ERR_INVALID_STATE;
    }

    memcpy(sched, &s_device_state.schedule, sizeof(device_schedule_t));
    return ESP_OK;
}

#if CONFIG_FIRMWARE_ENGINEERING
esp_err_t supervisor_operation_trigger_reload(void)
{
    if (!supervisor_operation_is_initialized()) {
        return ESP_ERR_INVALID_STATE;
    }

    if (s_device_state.reload_state.stage == RELOAD_NONE) {
        // Reset all bins to DISABLED status with scheduled_time = 0
        // This disables all future schedules, forcing check_state_transitions()
        // to automatically trigger RELOAD_NEEDS_RELOAD on the next tick
        for (int i = 0; i < 14; i++) {
            s_device_state.bins[i].status = DISABLED;
            s_device_state.bins[i].scheduled_time = 0;
        }
        
        ESP_LOGI(TAG, "Manual reload triggered via engineering interface - reset all bins to DISABLED");
        ESP_ERROR_CHECK(update_device_state());
        return ESP_OK;
    } else {
        ESP_LOGW(TAG, "Reload already in progress (stage: %d)", s_device_state.reload_state.stage);
        return ESP_ERR_INVALID_STATE;
    }
}

esp_err_t supervisor_operation_reset_pending_bins(void)
{
    if (!supervisor_operation_is_initialized()) {
        return ESP_ERR_INVALID_STATE;
    }

    time_t current_sec = time(NULL);

    if (!app_rtc_time_synced()) {
        ESP_LOGE(TAG, "Cannot reset bins: RTC time not synced");
        return ESP_ERR_INVALID_STATE;
    }

    // Step 1: Recalculate all scheduled times based on current schedule
    // This picks up any schedule changes even for bins that are TAKEN/MISSED/NO_RECORD
    if (s_device_state.schedule.type == SCHED_SIMPLE) {
        device_schedule_validation_t validation = apply_schedule(&s_device_state.schedule, &s_device_state, true);
        if (validation != SCHED_VALID) {
            ESP_LOGE(TAG, "Failed to recalculate schedule during bin reset: %d", validation);
            return ESP_FAIL;
        }
    } else {
        ESP_LOGE(TAG, "No valid schedule to apply");
        return ESP_FAIL;
    }

    // Step 2: Reset only future-dated bins to PENDING
    // This allows re-testing without factory reset, while preserving past dose history
    int reset_count = 0;
    for (int i = 0; i < 14; i++) {
        if (s_device_state.bins[i].scheduled_time > current_sec) {
            s_device_state.bins[i].status = PENDING;
            reset_count++;
            ESP_LOGI(TAG, "[ENGINEERING] Bin %d reset to PENDING (scheduled: %lld, now: %lld)",
                     i, (long long)s_device_state.bins[i].scheduled_time, (long long)current_sec);
        }
    }

    ESP_LOGI(TAG, "[ENGINEERING] Reset %d bins to PENDING for re-testing", reset_count);
    
    ESP_ERROR_CHECK(update_device_state());
    check_state_transitions();
    
    return ESP_OK;
}
#endif // CONFIG_FIRMWARE_ENGINEERING

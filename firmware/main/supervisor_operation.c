#include "supervisor_operation.h"
#include <string.h>
#include <esp_log.h>
#include "mqtt.h"
#include "device_config.h"
#include "ledc.h"
#include "network.h"
#include "shadow_state.h"
#include <stdatomic.h>

#define TAG "SUPERVISOR_OPERATION"

typedef enum {
    STATE_INIT,
    STATE_CONNECTING_NETIF,
    STATE_SYNCING_TIME,
    STATE_CONNECTING_MQTT,
    STATE_MQTT_CONNECTED,
    STATE_SHADOW_READY,
    STATE_OPERATIONAL
} supervisor_operation_state_t;

static atomic_bool s_init = ATOMIC_VAR_INIT(false);
static supervisor_operation_state_t s_state;
static device_state_t s_device_state;

static int MISSED_THRESHOLD_SEC = 15 * 60;  // 15 minutes (15 * 60 seconds)
static int RELOAD_TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes (5 * 60 seconds * 1000 ms)

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

static void print_schedule(const device_schedule_t* sched) {
    if (!sched) return;

    ESP_LOGI(TAG, "--- Schedule Info ---");
    // .36s ensures it won't overflow if it lacks a null terminator
    ESP_LOGI(TAG, "ID: %.36s", sched->id);
    ESP_LOGI(TAG, "Type: %s", get_schedule_type_str(sched->type));
    ESP_LOGI(TAG, "Take Effect: %s", get_take_effect_str(sched->take_effect));

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
            for (int i = 0; i < 14; i++) {
                bin_state_t* bs = &s_device_state.bins[i];
                if (bs->status == TAKE_NOW) {
                    blink_mask |= 1 << i;
                    green_mask |= 1 << i;
                }
            }
            
            ledc_set_idle_task(LED_DEVICE_STATE, (led_task_param_t){
                .device_state = {
                    .red = 0x0000,
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

    device_state_t state_copy;
    memcpy(&state_copy, &s_device_state, sizeof(device_state_t));

    // Attempt to apply schedule to copied state
    device_schedule_validation_t validation = apply_schedule(sched, &state_copy, false);
    if (validation == SCHED_VALID) {
        // Schedule valid!
        
        // Copy updated state from the applied copy 
        memcpy(&s_device_state, &state_copy, sizeof(device_state_t));

        ESP_ERROR_CHECK(update_device_state());
        ESP_ERROR_CHECK(shadow_state_report_schedule(&s_device_state.schedule));
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
        // Using %.34s for schedule_id to safely cap at the struct's defined 35 char length.
        ESP_LOGI(TAG, "  Bin %2d | Status: %d | Sched: %lld | Event: %lld | Open: %lld | Close: %lld | SchedID: %.34s",
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

    // Apply current schedule to the future state
    int rc = apply_schedule(&s_device_state.schedule, future_state, true);
    if (rc != 0) {
        ESP_LOGE(TAG, "apply_schedule failed (%d), aborting reload", rc);
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
    memcpy(&s_device_state.bins, &s_device_state.reload_state.future_state->bins,
         sizeof(s_device_state.bins));
    cleanup_reload();
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
        s_device_state.schedule = pers.schedule;
        s_device_state.epoch_week = pers.epoch_week;

        // Copy bin state
        for (uint8_t i = 0; i < 14; i++) {
            s_device_state.bins[i].status = pers.bins[i].status;
            memcpy(s_device_state.bins[i].schedule_id, pers.bins[i].schedule_id, SCHEDULE_ID_SIZE);
            s_device_state.bins[i].scheduled_time = pers.bins[i].scheduled_time;
            s_device_state.bins[i].event_time = pers.bins[i].event_time;
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

                if (s_device_state.reload_state.progress == s_device_state.reload_state.complete_mask) {
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
    device_event_t devev = {
        .timestamp = 0,
        .event_type = event_type,
        .bin_id = bin_id
    };

    if (app_rtc_get_utc_timestamp_ms(&devev.timestamp) != ESP_OK) {
        supervisor_assert_error(DEVERR_NO_RTC_TIME);
        return;
    }

    switch (devev.event_type) {
        case DEVEVT_DOOR_OPENED:
            handle_door_open(devev.bin_id);
            break;
        case DEVEVT_DOOR_CLOSED:
            handle_door_close(devev.bin_id);
            break;
        case DEVEVT_TAKEN:
            s_device_state.bins[devev.bin_id].status = TAKEN;
            s_device_state.bins[devev.bin_id].event_time = devev.timestamp;
            ESP_ERROR_CHECK(update_device_state());
            break;

        default:
            break;
    }
}

static void handle_device_event_nobin(device_event_type_t event_type)
{
    handle_device_event_bin(event_type, 0);
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

void supervisor_operation_init()
{
    s_state = STATE_INIT;
    load_state();

    // Init shadow state
    shadow_state_init();

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
        s_device_state.battery = battery_get_state();
        ESP_LOGI(TAG, "New battery state: %s", battery_status_str(s_device_state.battery));
        update_device_state();
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
                mqtt_publish_device_state(&s_device_state);
                shadow_state_on_connect();
                s_state = STATE_MQTT_CONNECTED;
            }
            break;
        case STATE_MQTT_CONNECTED:
            if (event->id == EVENT_SHADOW_READY) {
                shadow_state_report_schedule(&s_device_state.schedule);
                s_state = STATE_SHADOW_READY;
            }
            break;
        case STATE_SHADOW_READY:
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
                ESP_ERROR_CHECK(mqtt_publish_device_state(&s_device_state));
            }
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
        s_state = STATE_CONNECTING_MQTT;
    }
}

void supervisor_operation_tick()
{
    // Check reload timeout
    if (s_device_state.reload_state.stage == RELOAD_RELOADING) {
        int64_t dur = app_rtc_calc_duration_ms(s_device_state.reload_state.start_time, 
            app_rtc_get_relative_timestamp());
        if (dur > RELOAD_TIMEOUT_MS) {
            ESP_ERROR_CHECK(supervisor_submit_event(EVENT_RELOAD_TIMEOUT));
        }
    }

    check_state_transitions();
    set_led_idle_task();
}

esp_err_t supervisor_operation_get_schedule(device_schedule_t* sched)
{
    if (!supervisor_operation_is_initialized()) {
        return ESP_ERR_INVALID_STATE;
    }

    memcpy(sched, &s_device_state.schedule, sizeof(device_schedule_t));
    return ESP_OK;
}

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
    STATE_OPERATIONAL,
    STATE_FAILSAFE
} supervisor_operation_state_t;

static atomic_bool s_init = ATOMIC_VAR_INIT(false);
static supervisor_operation_state_t s_state;
static device_state_t s_device_state;

static int MISSED_THRESHOLD_SEC = 15 * 60;  // 15 minutes (15 * 60 seconds)

static const char* get_failsafe_reason_str(device_failsafe_reason_t reason) {
    switch(reason) {
        case DEVICE_OPERATIONAL: return "OPERATIONAL";
        case FAILSAFE_NO_SCHEDULE: return "FAILSAFE_NO_SCHEDULE";
        default: return "UNKNOWN";
    }
}

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

static esp_err_t update_device_state()
{
    esp_err_t err;

    // Mark updated at timestamp
    // Can fail if we can't get a valid time
    if ((err = app_rtc_get_utc_timestamp_ms(&s_device_state.modified_at)) != ESP_OK) {
        return err;
    }

    /* NVS Persistence */

    // Build persistent state struct
    device_persistent_state_t pers;

    // Ensure struct is empty
    memset(&pers, 0, sizeof(pdFREERTOS_ERRNO_EBADE));

    // Copy fields
    pers.modified_at = s_device_state.modified_at;
    pers.synced_at = s_device_state.synced_at;
    pers.schedule = s_device_state.schedule; 
    pers.epoch_week = s_device_state.epoch_week;
    for (int i = 0; i < 14; i++) {
        pers.bins[i].status = s_device_state.bins[i].status;
        pers.bins[i].scheduled_time = s_device_state.bins[i].scheduled_time;
        pers.bins[i].event_time = s_device_state.bins[i].event_time;
        strncpy(pers.bins[i].schedule_id, s_device_state.bins[i].schedule_id, SCHEDULE_ID_SIZE);
    }

    // Save state to NVS
    if ((err = devcfg_set_device_state(&pers)) != ESP_OK) {
        return err;
    }

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
        device_state_t* state)
{
    bin_state_t* bin_state = &state->bins[bin_id];

    // Check current time
    time_t current_sec = time(NULL);

    // Check if we should update this bin
    if (should_schedule_bin(bin_state, current_sec)) {
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
        strncpy(bin_state->schedule_id, state->schedule.id, SCHEDULE_ID_SIZE);
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
                schedule_bin(i * 2, NULL, state);
                schedule_bin(i * 2 + 1, NULL, state);
            } else if(periods_in_day == 1) {
                schedule_bin(i * 2, &bins[i * 2], state);
                schedule_bin(i * 2 + 1, NULL, state);
            } else if(periods_in_day == 2) {
                schedule_bin(i * 2, &bins[i * 2], state);
                schedule_bin(i * 2 + 1, &bins[i * 2 + 1], state);
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
    strncpy(s_device_state.schedule.rejected_id, sched->id, SCHEDULE_ID_SIZE);
    s_device_state.schedule.rejected_reason = validation;
}

static void print_state(const device_state_t* state) {
    if (!state) return;

    ESP_LOGI(TAG, "=== Device State ===");
    ESP_LOGI(TAG, "Modified At: %lld (Unix timestamp in ms)", state->modified_at);
    ESP_LOGI(TAG, "Battery: %d%% | Charging: %s", state->battery, state->charging ? "YES" : "NO");
    ESP_LOGI(TAG, "Reloading: %s", state->reloading ? "YES" : "NO");
    ESP_LOGI(TAG, "Failsafe Reason: %s", get_failsafe_reason_str(state->failsafe_reason));
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

static bool validate_state(const device_state_t* state, device_failsafe_reason_t* error_reason)
{
    // Clear error
    *error_reason = DEVICE_OPERATIONAL;

    if (state->schedule.type == SCHED_NONE) {
        *error_reason = FAILSAFE_NO_SCHEDULE;
        return false;
    }

    return true;
}

static void check_state_transitions()
{
    bool changed = false;

    if (!app_rtc_time_synced()) {
        // Can't check state transitions if the time isn't accurate
        return;
    }

    time_t current_sec = time(NULL);

    for (int i = 0; i < 14; i++) {
        bin_state_t* bin_state = &s_device_state.bins[i];

        // If the bin has a scheduled time set
        if (bin_state->scheduled_time > 0) { 
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
        s_device_state.failsafe_reason = FAILSAFE_STATE_CORRUPTED;
        ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_FAILSAFE, (intptr_t)FAILSAFE_STATE_CORRUPTED, 100));
    }
        
    // Print loaded state
    print_state(&s_device_state);

    // Check for state changes on load
    check_state_transitions();
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
            return true;
        } else {
            return next_bin->scheduled_time > bin_state->scheduled_time;
        }
    } else if (bin_state->status == PENDING) {
        // Accept early doses only if taken after the previously scheduled dose
        bin_state_t* prev_bin = get_prev_scheduled_bin(bin_state->scheduled_time);
        if (!prev_bin) {
            return true;
        } else {
            return prev_bin->scheduled_time < bin_state->scheduled_time;
        }
    }

    return false;
}

static void handle_door_open(int door_id)
{
    bin_state_t* bin_state = &s_device_state.bins[door_id];
    bool taken_event = should_mark_taken(bin_state);

    door_light_effect(door_id, true, taken_event);

    // Update state
    s_device_state.doors |= 1 << door_id;
    bin_state->opened_at = app_rtc_get_relative_timestamp();

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
    
    // Fire event
    ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_BIN_TAKEN, (intptr_t)door_id, 100));

    update_device_state();
}

static void update_state_from_runtime(device_state_t* state)
{
    state->battery = 100;
    state->charging = false;
    state->reloading = false;
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
    if (event->id == EVENT_FAILSAFE) {
        // We are requested to go into failsafe mode
        // Drop everything and handle this first
        s_state = STATE_FAILSAFE;

        // Check if a reason is specified
        device_failsafe_reason_t reason = (device_failsafe_reason_t)event->payload;
        if (reason != DEVICE_OPERATIONAL) {
            // Set the reason in the device state so we can report it to the user
            s_device_state.failsafe_reason = reason;
        }

        // Start lighting effect
        ledc_set_task(LED_BREATHE, (led_task_param_t) {
            .blink = {
                .red = LED_ALL_DOORS,
                // Exclude some bins to indicate the issue to the user
                .green = LED_ALL_DOORS - (int)s_device_state.failsafe_reason
            }
        }, 0);
    } else if(event->id == EVENT_DOOR_OPENED) {
        handle_door_open((int)event->payload);
    } else if(event->id == EVENT_DOOR_CLOSED) {
        handle_door_close((int)event->payload);
    } else if(event->id == EVENT_BIN_TAKE_NOW) {
        // Start breathing effect on the specific bin
        ledc_set_task(LED_BREATHE, (led_task_param_t) {
                .breathe = {
                    .red = 0x0000,
                    .green = (1 << (int)event->payload)
                }
        }, 0);
    } else if(event->id == EVENT_BIN_TAKEN) {
        // Blink for 6 seconds to indicate taken
        ledc_set_task(LED_BLINK, (led_task_param_t) {
                .breathe = {
                    .red = 0x0000,
                    .green = (1 << (int)event->payload)
                }
        }, 6000);
    } else if(event->id == EVENT_BIN_MISSED) {
        // Blink for 1 minute to indicate missed
        ledc_set_task(LED_BLINK, (led_task_param_t) {
                .breathe = {
                    .red = (1 << (int)event->payload),
                    .green = (1 << (int)event->payload)
                }
        }, 60000);
    }

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
    check_state_transitions();
}

esp_err_t supervisor_operation_get_schedule(device_schedule_t* sched)
{
    if (!supervisor_operation_is_initialized()) {
        return ESP_ERR_INVALID_STATE;
    }

    memcpy(sched, &s_device_state.schedule, sizeof(device_schedule_t));
    return ESP_OK;
}

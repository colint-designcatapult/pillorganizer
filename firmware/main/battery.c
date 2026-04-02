#include "battery.h"
#include "esp_sleep.h"
#include "pill_pins.h"
#include <driver/gpio.h>
#include "supervisor.h"
#include <stdio.h>
#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

#define TAG "BATTERY"

// Protects s_battery_state from concurrent Task/ISR mutations
static portMUX_TYPE s_battery_lock = portMUX_INITIALIZER_UNLOCKED;

// Default state. Saved in RTC to persist deep sleep.
static RTC_DATA_ATTR battery_state_t s_battery_state = {
    .presence = BATTERY_PRESENCE_UNKNOWN,
    .charge_state = BATTERY_CHARGE_UNKNOWN,
    .level = BATTERY_LEVEL_UNKNOWN,
    .usb_power_connected = false,
    .power_good = false
};

// State tracking for logic and debouncing
static RTC_DATA_ATTR uint32_t s_consecutive_bat_highs = 0;
static RTC_DATA_ATTR uint8_t s_chg_bounce_count = 0;
static RTC_DATA_ATTR uint32_t s_last_charge_toggle_ticks = 0;

#define BAT_CONSECUTIVE_READINGS_FOR_LEVEL  10
static RTC_DATA_ATTR uint32_t s_consecutive_level_readings = 0;
static RTC_DATA_ATTR battery_level_t s_pending_level = BATTERY_LEVEL_UNKNOWN;

static char s_status_str_buffer[64] = {0};

// Thresholds
#define BAT_CONSECUTIVE_HIGHS_FOR_CONNECTED 5 
#define BAT_PULSE_ADC_THRESHOLD 1500
#define BAT_LEVEL_FULL_THRESHOLD     4095
#define BAT_LEVEL_CRITICAL_THRESHOLD 3900


static void notify_state_change()
{
    // Note: Do not call this while holding s_battery_lock!
    ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_BATTERY_CHANGE, 0, pdMS_TO_TICKS(100)));
}

void battery_init()
{
    int charge_level = gpio_get_level(BAT_CHARGE_PIN);
    int pgood_level = gpio_get_level(BAT_PGOOD_PIN);

    // Pins are active low
    battery_charge_state_t new_charge_state = (charge_level == 0) ? BATTERY_CHARGE_CHARGING : BATTERY_CHARGE_NOT_CHARGING;
    bool new_power_good = (pgood_level == 0);

    bool should_notify = false;

    portENTER_CRITICAL(&s_battery_lock);
    if (s_battery_state.charge_state != new_charge_state) {
        s_battery_state.charge_state = new_charge_state;
        should_notify = true;
    }

    if (s_battery_state.power_good != new_power_good) {
        s_battery_state.power_good = new_power_good;
        should_notify = true;
    }
    portEXIT_CRITICAL(&s_battery_lock);

    if (should_notify) {
        notify_state_change();
    }
}

battery_state_t battery_get_state(void)
{
    battery_state_t copy;
    portENTER_CRITICAL(&s_battery_lock);
    copy = s_battery_state;
    portEXIT_CRITICAL(&s_battery_lock);
    return copy;
}

battery_presence_t battery_get_presence()
{
    battery_presence_t presence;
    portENTER_CRITICAL(&s_battery_lock);
    presence = s_battery_state.presence;
    portEXIT_CRITICAL(&s_battery_lock);
    return presence;
}

bool RTC_IRAM_ATTR battery_submit_adc_readings(uint32_t bat_start, uint32_t bat_end, uint32_t vbus)
{
    bool state_changed = false;
    
    portENTER_CRITICAL(&s_battery_lock);

    // 1. USB Power Detection
    bool usb_connected = (vbus > 500); 
    if (s_battery_state.usb_power_connected != usb_connected) {
        s_battery_state.usb_power_connected = usb_connected;
        state_changed = true;
    }

    // 2. Battery Connection Filtering 
    bool start_is_high = (bat_start > BAT_PULSE_ADC_THRESHOLD);
    bool end_is_high = (bat_end > BAT_PULSE_ADC_THRESHOLD);

    if (!start_is_high || !end_is_high) {
        // A real battery never drops LOW. If we see a LOW, we are seeing the 2Hz pulse.
        s_consecutive_bat_highs = 0;
        if (s_battery_state.presence != BATTERY_PRESENCE_DISCONNECTED) {
            s_battery_state.presence = BATTERY_PRESENCE_DISCONNECTED;
            
            // Ignore the /CHG pin if battery disconnected
            if (s_battery_state.charge_state != BATTERY_CHARGE_NOT_CHARGING) {
                s_battery_state.charge_state = BATTERY_CHARGE_NOT_CHARGING;
            }
            state_changed = true;
        }
    } else {
        // Both readings are HIGH. Is it a real battery, or just the HIGH phase of the pulse?
        if (s_consecutive_bat_highs < BAT_CONSECUTIVE_HIGHS_FOR_CONNECTED) {
            s_consecutive_bat_highs++;
        } else {
            // If USB is plugged in, the ADC is blinded by 5V and CHG might be bouncing.
            // Do not override a disconnected state confirmed by the CHG pin bounce detector!
            if (!(s_battery_state.usb_power_connected && s_battery_state.presence == BATTERY_PRESENCE_DISCONNECTED)) {
                if (s_battery_state.presence != BATTERY_PRESENCE_CONNECTED) {
                    s_battery_state.presence = BATTERY_PRESENCE_CONNECTED;
                    state_changed = true;
                    
                    if (s_battery_state.charge_state != BATTERY_CHARGE_UNKNOWN) {
                        s_battery_state.charge_state = BATTERY_CHARGE_UNKNOWN;
                    }
                }
            }
        }
    }

// 3. Battery Level Debouncing (10 Sequential Readings)
    if (s_battery_state.presence == BATTERY_PRESENCE_CONNECTED || s_battery_state.presence == BATTERY_PRESENCE_UNKNOWN) {
        
        battery_level_t reading_level;
        if (bat_start >= BAT_LEVEL_FULL_THRESHOLD) {
            reading_level = BATTERY_LEVEL_FULL;
        } else if (bat_start >= BAT_LEVEL_CRITICAL_THRESHOLD) {
            reading_level = BATTERY_LEVEL_CRITICAL;
        } else {
            reading_level = BATTERY_LEVEL_SHUTOFF;
        }

        if (reading_level == s_pending_level) {
            if (s_consecutive_level_readings < BAT_CONSECUTIVE_READINGS_FOR_LEVEL) {
                s_consecutive_level_readings++;
            }
            
            // If we have seen this level 10 times in a row, commit it
            if (s_consecutive_level_readings >= BAT_CONSECUTIVE_READINGS_FOR_LEVEL) {
                if (s_battery_state.level != s_pending_level) {
                    s_battery_state.level = s_pending_level;
                    state_changed = true;
                }
            }
        } else {
            // The reading changed (either a real shift or ADC noise). Reset the counter.
            s_pending_level = reading_level;
            s_consecutive_level_readings = 1;
        }
    }

    portEXIT_CRITICAL(&s_battery_lock);
    return state_changed;
}

void battery_submit_charge_pin(bool charge_pin_active)
{
    battery_charge_state_t new_charge_state = charge_pin_active ? BATTERY_CHARGE_CHARGING : BATTERY_CHARGE_NOT_CHARGING;
    bool should_notify = false;
    uint32_t now = xTaskGetTickCount();
    
    portENTER_CRITICAL(&s_battery_lock);
    
    if (s_battery_state.charge_state != new_charge_state) {
        
        // Detect BQ24074 2Hz square wave bouncing when battery is missing 
        if (s_last_charge_toggle_ticks != 0) {
            uint32_t diff = now - s_last_charge_toggle_ticks;
            
            if (diff < pdMS_TO_TICKS(1000)) {
                s_chg_bounce_count++;
                
                // Require 4 rapid toggles to confirm a bounce, rather than a single fast charge termination
                if (s_chg_bounce_count >= 4) {
                    if (s_battery_state.presence != BATTERY_PRESENCE_DISCONNECTED) {
                        s_battery_state.presence = BATTERY_PRESENCE_DISCONNECTED;
                        should_notify = true;
                    }
                }
            } else if (diff > pdMS_TO_TICKS(2000)) {
                // If it stabilizes for more than 2 seconds, clear the bounce history
                s_chg_bounce_count = 0;
                
                // Auto-recover presence if it was previously marked disconnected due to bouncing
                if (s_battery_state.usb_power_connected && s_battery_state.presence == BATTERY_PRESENCE_DISCONNECTED) {
                    s_battery_state.presence = BATTERY_PRESENCE_CONNECTED;
                    should_notify = true;
                }
            }
        }

        s_last_charge_toggle_ticks = now;
        s_battery_state.charge_state = new_charge_state;

        // Only dispatch a standard CHG pin event if we believe a battery is actually there
        if (s_battery_state.presence != BATTERY_PRESENCE_DISCONNECTED) {
            should_notify = true;
        }
    }
    
    portEXIT_CRITICAL(&s_battery_lock);

    if (should_notify) {
        notify_state_change();
    }
}

void battery_submit_pgood_pin(bool pgood_active)
{
    bool should_notify = false;

    portENTER_CRITICAL(&s_battery_lock);
    if (s_battery_state.power_good != pgood_active) {
        s_battery_state.power_good = pgood_active;
        should_notify = true;
    }
    portEXIT_CRITICAL(&s_battery_lock);

    if (should_notify) {
        notify_state_change();
    }
}

const char* battery_status_str(battery_state_t state)
{
    const char* pres_str = (state.presence == BATTERY_PRESENCE_CONNECTED) ? "CONN" : 
                           (state.presence == BATTERY_PRESENCE_DISCONNECTED) ? "DISC" : "UNK";
                           
    const char* chg_str = (state.charge_state == BATTERY_CHARGE_CHARGING) ? "CHG" : 
                          (state.charge_state == BATTERY_CHARGE_NOT_CHARGING) ? "IDLE" : "UNK";
                          
    const char* lvl_str = (state.level == BATTERY_LEVEL_FULL) ? "FULL" : 
                          (state.level == BATTERY_LEVEL_CRITICAL) ? "CRIT" : 
                          (state.level == BATTERY_LEVEL_SHUTOFF) ? "SHUT" : "UNK";
                          
    const char* usb_str = state.usb_power_connected ? "USB" : "BAT";

    // Standard string formatting is thread-safe on local copies of state structs
    snprintf(s_status_str_buffer, sizeof(s_status_str_buffer), 
        "[USB:%s PG:%d PRES:%s CHG:%s LVL:%s]", usb_str, state.power_good, pres_str, chg_str, lvl_str);
        
    return s_status_str_buffer;
}
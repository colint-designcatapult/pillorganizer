#pragma once
#include <stdint.h>
#include <stdbool.h>
#include <esp_sleep.h>

typedef enum {
    BATTERY_PRESENCE_UNKNOWN,
    BATTERY_PRESENCE_DISCONNECTED,
    BATTERY_PRESENCE_CONNECTED
} battery_presence_t;

typedef enum {
    BATTERY_CHARGE_UNKNOWN,
    BATTERY_CHARGE_NOT_CHARGING,
    BATTERY_CHARGE_CHARGING
} battery_charge_state_t;

typedef enum {
    BATTERY_LEVEL_UNKNOWN,
    BATTERY_LEVEL_SHUTOFF,
    BATTERY_LEVEL_CRITICAL,
    BATTERY_LEVEL_FULL
} battery_level_t;

typedef struct {
    battery_presence_t presence;
    battery_charge_state_t charge_state;
    battery_level_t level;
    bool usb_power_connected;
    bool power_good;
} battery_state_t;

void battery_init();

// Submit raw ADC values for battery start/end and VBUS. Returns true if state changed.
bool battery_submit_adc_readings(uint32_t bat_start, uint32_t bat_end, uint32_t vbus);

// Submit /CHG pin state
void battery_submit_charge_pin(bool charge_pin_active);

// Submit /PG pin state
void battery_submit_pgood_pin(bool pgood_active);

// Retrieve a copy of the current hardware battery state
battery_state_t battery_get_state(void);

// Retrieve just the presence field (safe for RTC_IRAM_ATTR)
battery_presence_t battery_get_presence(void);

bool battery_is_pulse_high(uint32_t bat_start, uint32_t bat_end);

// Format battery state into a string
const char* battery_status_str(battery_state_t state);

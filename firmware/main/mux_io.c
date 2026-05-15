#include "mux_io.h"
#include "ledc.h"
#include "sdkconfig.h"

#if CONFIG_EMULATOR_MODE

/* No MUX hardware in the emulator — provide empty stubs. */
void mux_init(void) { }
void mux_fresh_boot(void) { }
void mux_wake_deep_sleep(void) { }
bool mux_wake_deep_sleep_early(void) { return true; }
void mux_prep_deep_sleep(void) { }

#else /* !CONFIG_EMULATOR_MODE */

#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "ulp_adc.h"
#include "ulp.h"          
#include "ulp_main.h"     
#include "esp_sleep.h"
#include "esp_system.h"
#include "esp_task_wdt.h"
#include "driver/rtc_io.h"
#include "driver/gpio.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/sens_reg.h"
#include "esp_adc/adc_oneshot.h"
#include "ulp/mux_config.h"
#include "mux_io.h"
#include "esp_intr_alloc.h"
#include "soc/periph_defs.h"
#include "esp_sleep.h"
#include "pill_pins.h"
#include "esp_log.h"
#include "supervisor.h"
#include "battery.h"
#include <stdatomic.h>

#define TAG "MUX_IO"

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

/* Declare our ULP variables */
extern uint32_t ulp_adc_readings_0;
extern uint32_t ulp_adc_readings_1;
extern uint32_t ulp_active_buffer;
extern uint32_t ulp_primed;

static TaskHandle_t ulp_task_handle = NULL;
static atomic_bool s_raw_print = ATOMIC_VAR_INIT(false);

#define ADC_READINGS 16
#define ADC_DOOR_CHANNEL_START 0
#define ADC_DOOR_CHANNEL_END 13
#define ADC_NUM_DOOR_CHANNELS (ADC_DOOR_CHANNEL_END - ADC_DOOR_CHANNEL_START + 1)

#define SCALE_FACTOR 256  // Scales integers to give us "decimal" precision
#define ALPHA_SHIFT 3     // Equivalent to an alpha of 1/8 for smoothing

/* --- Wake Reasons Bitmask --- */
#define WAKE_REASON_NONE    0
#define WAKE_REASON_DOOR    (1 << 0)
#define WAKE_REASON_BATTERY (1 << 1)

typedef enum {
    DOOR_CLOSED = 0,
    DOOR_OPEN = 1
} door_state_t;

static RTC_DATA_ATTR door_state_t rtc_last_known_state[ADC_NUM_DOOR_CHANNELS] = {DOOR_CLOSED};

/* State tracking for each channel. 
 * Must be in RTC_DATA_ATTR to survive deep sleep. */
typedef struct {
    int32_t ema;           // Scaled Exponential Moving Average
    int32_t mad;           // Scaled Mean Absolute Deviation
    int32_t open_baseline; // The EMA recorded right before the door opened
    door_state_t state;
    uint8_t debounce_cnt;  // NEW: Tracks consecutive readings for state changes
    bool initialized;
    uint8_t reset_ctr;
} ch_stats_t;

static RTC_DATA_ATTR ch_stats_t ch_stats[ADC_NUM_DOOR_CHANNELS];
static RTC_DATA_ATTR uint32_t ulp_ctr = 0;

/* Previous cycle's ledc_get_state() value. Initialised to 0 (not idle, no
 * red LEDs) so the first cycle after boot/wake always re-baselines cleanly. */
static RTC_DATA_ATTR uint16_t s_prev_led_state = 0;

static void init_ulp_program(void);
static void start_ulp_program(void);


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
static uint32_t RTC_IRAM_ATTR process_ulp_events(void)
{    
    uint32_t wake_flags = WAKE_REASON_NONE;
    // This is the first iteration, prev values invalid
    if (ulp_ctr++ == 0) {
        return wake_flags;
    }

    /* Read from the INACTIVE buffer (just completed) to prevent race conditions.
     * The ACTIVE buffer (currently being filled) holds the previous cycle's data
     * and is safe to read for bat_start_val — ch14 won't be overwritten for ~140ms. */
    uint32_t active_buf = ulp_active_buffer & 0xFFFF;
    uint32_t* values      = (active_buf == 0) ? &ulp_adc_readings_1 : &ulp_adc_readings_0;
    uint32_t* prev_values = (active_buf == 0) ? &ulp_adc_readings_0 : &ulp_adc_readings_1;

    /* ==========================================================
     * Battery Presence & Square Wave Filtering
     * ========================================================== */
    /* bat_start_val comes from the previous cycle's ch14 reading (cross-cycle
     * square wave detection). bat_end_val and vbus from the current cycle. */
    uint32_t bat_start_val = prev_values[14] & 0xFFFF;
    uint32_t bat_end_val   = values[14] & 0xFFFF;
    uint32_t vbus_val      = values[15] & 0xFFFF;

    // Delegate EVERYTHING to the battery module! It returns true if the state meaningfully changed.
    if (battery_submit_adc_readings(bat_start_val, bat_end_val, vbus_val)) {
        wake_flags |= WAKE_REASON_BATTERY;
    }

    if (atomic_load_explicit(&s_raw_print, memory_order_relaxed)) {
        printf("MUX raw:");
        for (int i = 0; i <= 15; i++) {
            printf("\t%lu", values[i] & 0xFFFF);
        }
        printf("\t%lu\t%lu\t%lu\n", bat_start_val, bat_end_val, active_buf);
    }

    // 2. Inhibit door logic if no battery is present AND the pulse is currently HIGH
    if (battery_get_presence() == BATTERY_PRESENCE_DISCONNECTED && battery_is_pulse_high(bat_start_val, bat_end_val)) {
        // Throw away these ULP reads so they don't corrupt the EMA/MAD door baselines.
        return wake_flags; 
    }

    /* ==========================================================
     * LED Interference Suppression
     * ========================================================== */
    uint16_t led_state  = ledc_get_state();
    bool     is_idle    = (led_state  >> 15) & 1;
    bool     was_idle   = (s_prev_led_state >> 15) & 1;
    uint16_t red_mask   =  led_state  & 0x3FFF;
    uint16_t prev_red   =  s_prev_led_state & 0x3FFF;
    s_prev_led_state    =  led_state;

    // If we are currently playing an LED animation, skip processing
    if (!is_idle) {
        return wake_flags;
    }

    // Re-baseline closed doors on red transition OR if we were previously playing an animation
    if (red_mask != prev_red || !was_idle) {
        for (int door = 0; door < ADC_NUM_DOOR_CHANNELS; door++) {
            
            if (ch_stats[door].state == DOOR_CLOSED) {
                ch_stats[door].initialized = false;
                ch_stats[door].reset_ctr = 3; // cooldown for 3 samples before reinitializing
            }
        }
    }

    /* ==========================================================
     * Door Channel Processing
     * ========================================================== */

    #define AMBIENT_CHANGE_THRESHOLD 3
    #define DEBOUNCE_SAMPLES         2

    int candidate_state_changes = 0;

    for (int ch = ADC_DOOR_CHANNEL_START; ch <= ADC_DOOR_CHANNEL_END; ch++) {
        int door = ch - ADC_DOOR_CHANNEL_START;
        ch_stats_t* stats = &ch_stats[door];

        if (stats->reset_ctr > 0) {
            stats->reset_ctr--;
            continue;
        }
        
        int32_t s_val = (values[ch] & 0xFFFF) * SCALE_FACTOR; 

        if (!stats->initialized) {
            stats->ema = s_val;
            stats->mad = 5 * SCALE_FACTOR;
            stats->state = DOOR_CLOSED;
            stats->debounce_cnt = 0;
            stats->initialized = true;
            stats->reset_ctr = 0;
            continue;
        }

        if (stats->state == DOOR_CLOSED) {
            int32_t diff = s_val - stats->ema;
            if (diff > (stats->mad * 5)) candidate_state_changes++;
        } else {
            if (s_val < (stats->open_baseline + (stats->mad * 2))) candidate_state_changes++;
        }
    }

    bool is_ambient_event = (candidate_state_changes >= AMBIENT_CHANGE_THRESHOLD);

    for (int ch = ADC_DOOR_CHANNEL_START; ch <= ADC_DOOR_CHANNEL_END; ch++) {
        int door = ch - ADC_DOOR_CHANNEL_START;
        ch_stats_t* stats = &ch_stats[door];

        if (stats->reset_ctr > 0) {
            continue;
        }
        
        int32_t s_val = (values[ch] & 0xFFFF) * SCALE_FACTOR;

        if (is_ambient_event) {
            stats->ema = s_val;
            stats->debounce_cnt = 0; 
            continue;
        }

        if (stats->state == DOOR_CLOSED) {
            int32_t diff = s_val - stats->ema;
            int32_t abs_diff = (diff > 0) ? diff : -diff;

            if (diff > (stats->mad * 5)) {
                stats->debounce_cnt++;
                if (stats->debounce_cnt >= DEBOUNCE_SAMPLES) {
                    stats->state = DOOR_OPEN;
                    stats->open_baseline = stats->ema; 
                    stats->debounce_cnt = 0;
                    wake_flags |= WAKE_REASON_DOOR;
                }
            } else {
                stats->debounce_cnt = 0; 
                stats->ema += (diff >> ALPHA_SHIFT);
                stats->mad += ((abs_diff - stats->mad) >> ALPHA_SHIFT);

                if (stats->mad < (30 * SCALE_FACTOR)) {
                    stats->mad = 30 * SCALE_FACTOR;
                }           
            }
        } else {
            if (s_val < (stats->open_baseline + (stats->mad * 2))) {
                stats->debounce_cnt++;
                if (stats->debounce_cnt >= DEBOUNCE_SAMPLES) {
                    stats->state = DOOR_CLOSED;
                    stats->ema = s_val; 
                    stats->debounce_cnt = 0;
                    wake_flags |= WAKE_REASON_DOOR;
                }
            } else {
                stats->debounce_cnt = 0; 
            }
        }
    }
    
    return wake_flags;
}
#pragma GCC diagnostic pop

static void IRAM_ATTR ulp_isr_handler(void *arg)
{
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    vTaskNotifyGiveFromISR(ulp_task_handle, &xHigherPriorityTaskWoken);
    
    if (xHigherPriorityTaskWoken) {
        portYIELD_FROM_ISR();
    }
}

static void ulp_event_task(void *arg)
{
    /* Subscribe to the global hardware Task Watchdog Timer (60s) */
    ESP_ERROR_CHECK(esp_task_wdt_add(NULL));

    while (1) {
        uint32_t notified = ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(10000));

        if (notified == 0) {
            ESP_LOGE(TAG, "ULP software watchdog timeout! Resetting...");
            esp_restart();
        }

        /* Feed the hardware watchdog */
        esp_task_wdt_reset();

        // Process the new events (or retrieve state updated during wake stub)
        uint32_t wake_reasons = process_ulp_events();

        // 1. Handle Battery
        if (wake_reasons & WAKE_REASON_BATTERY) {
            ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_BATTERY_CHANGE, 0, pdMS_TO_TICKS(100)));
        }

        // 2. Handle Doors based on RTC state vs known state
        for (int i = 0; i < ADC_NUM_DOOR_CHANNELS; i++) {
            if (ch_stats[i].state != rtc_last_known_state[i]) {
                
                ESP_LOGI(TAG, "Door %d | STATE: %s | Real ADC: %ld | MAD: %ld", 
                         i, 
                         ch_stats[i].state == DOOR_OPEN ? "OPEN" : "CLOSED",
                         ch_stats[i].ema / SCALE_FACTOR, 
                         ch_stats[i].mad / SCALE_FACTOR);
                
                esp_err_t err;
                if (ch_stats[i].state == DOOR_OPEN) {
                    err = supervisor_submit_event_block(EVENT_DOOR_OPENED, (intptr_t)i, pdMS_TO_TICKS(10));
                } else {
                    err = supervisor_submit_event_block(EVENT_DOOR_CLOSED, (intptr_t)i, pdMS_TO_TICKS(10));
                }

                // Sync the state once successful
                if (err == ESP_OK) {
                    rtc_last_known_state[i] = ch_stats[i].state;
                }
            }
        }
    }
}


void mux_init()
{
    /* 1. Setup the FreeRTOS processing task pinned to Core 0 (PRO CPU) */
    xTaskCreatePinnedToCore(ulp_event_task, "ulp_event_task", 4096, NULL, 5, &ulp_task_handle, 0);

    /* 2. Register the ULP callback using the official ESP-IDF API 
     * This attaches our handler safely behind the scenes without 
     * colliding with the Brownout detector.
     */
    ESP_ERROR_CHECK(ulp_isr_register(ulp_isr_handler, NULL));
    
    /* 3. Enable the specific ULP interrupt bit in the RTC controller so it fires */
    REG_SET_BIT(RTC_CNTL_INT_ENA_REG, RTC_CNTL_ULP_CP_INT_ENA);

    ESP_LOGI(TAG, "MUX driver initialized");
}

void mux_prep_deep_sleep()
{
    /* Clean up the interrupt enable bit so we don't leak logic on the next wake cycle */
    REG_CLR_BIT(RTC_CNTL_INT_ENA_REG, RTC_CNTL_ULP_CP_INT_ENA);
    
    ESP_ERROR_CHECK(esp_sleep_enable_ulp_wakeup());
}

void mux_fresh_boot()
{
    /* Stop the ULP timer before loading the binary to prevent crashing the ULP FSM 
     * in the event it was left running across a warm/software reset. */
    ulp_timer_stop();

    // Wait for halting the ULP to take effect before we mess with RTC memory and load the program
    vTaskDelay(pdMS_TO_TICKS(200));

    init_ulp_program();
    start_ulp_program();
}

void mux_wake_deep_sleep()
{
    // Nothing here. 
}

bool RTC_IRAM_ATTR mux_wake_deep_sleep_early()
{
    // Process events and return true ONLY if it warrants a full wake up
    uint32_t wake_reasons = process_ulp_events();
    return (wake_reasons > 0);
}

static void init_ulp_program(void)
{
    // Clear RTC memory to ensure clean state on first boot (won't affect deep sleep wake cycles)
    memset((void*)ch_stats, 0, sizeof(ch_stats));
    memset((void*)rtc_last_known_state, 0, sizeof(rtc_last_known_state));

    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    ulp_adc_cfg_t cfg = {
        .adc_n    = (adc_unit_t)MUX_ADC_UNIT,
        .channel  = (adc_channel_t)MUX_ADC_CHANNEL,
        .atten    = (adc_atten_t)MUX_ADC_ATTEN,
        .width    = (adc_bitwidth_t )MUX_ADC_WIDTH,
        .ulp_mode = ADC_ULP_MODE_FSM,
    };

    ESP_ERROR_CHECK(ulp_adc_init(&cfg));

    /* Initialize the RTC GPIOs so ULP can drive the MUX */
    rtc_gpio_init(MUX_PIN_A);
    rtc_gpio_set_direction(MUX_PIN_A, RTC_GPIO_MODE_OUTPUT_ONLY);
    
    rtc_gpio_init(MUX_PIN_B);
    rtc_gpio_set_direction(MUX_PIN_B, RTC_GPIO_MODE_OUTPUT_ONLY);
    
    rtc_gpio_init(MUX_PIN_C);
    rtc_gpio_set_direction(MUX_PIN_C, RTC_GPIO_MODE_OUTPUT_ONLY);
    
    rtc_gpio_init(MUX_PIN_D);
    rtc_gpio_set_direction(MUX_PIN_D, RTC_GPIO_MODE_OUTPUT_ONLY);

    /* 10ms ULP wakeup period — one channel sampled per tick, 16 ticks per cycle (~160ms) */
    ulp_set_wakeup_period(0, 10000);

#if CONFIG_IDF_TARGET_ESP32
#ifndef CONFIG_FIRMWARE_ENGINEERING
    /* Disconnect JTAG/Bootstrapping pins to save deep sleep power.
     * Skipped when engineering mode is enabled to allow JTAG debugging. */
    rtc_gpio_isolate(GPIO_NUM_12);
    rtc_gpio_isolate(GPIO_NUM_15);
#endif
#endif

    esp_deep_sleep_disable_rom_logging();
}

static void start_ulp_program(void)
{
    /* Start the program */
    esp_err_t err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);
}

void mux_force_door_state_reset(int door_id) {
  if (door_id >= 0 && door_id < ADC_NUM_DOOR_CHANNELS) {
    ch_stats[door_id].initialized = false;
    ESP_LOGI(TAG, "Forced state reset for door %d", door_id);
  }
}

bool mux_eng_toggle_raw_print(void)
{
    bool prev = atomic_load_explicit(&s_raw_print, memory_order_relaxed);
    atomic_store_explicit(&s_raw_print, !prev, memory_order_relaxed);
    return !prev;
}

#endif /* !CONFIG_EMULATOR_MODE */

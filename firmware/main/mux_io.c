#include "mux_io.h"
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "ulp_adc.h"
#include "ulp.h"          
#include "ulp_main.h"     
#include "esp_sleep.h"
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

#define TAG "MUX_IO"

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

/* Declare our ULP variables */
extern uint32_t ulp_adc_readings_0;
extern uint32_t ulp_adc_readings_1;
extern uint32_t ulp_active_buffer;

static TaskHandle_t ulp_task_handle = NULL;

#define ADC_READINGS 17
#define ADC_DOOR_CHANNEL_START 1
#define ADC_DOOR_CHANNEL_END 14
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
} ch_stats_t;

static RTC_DATA_ATTR ch_stats_t ch_stats[ADC_NUM_DOOR_CHANNELS];

static void init_ulp_program(void);
static void start_ulp_program(void);

static uint32_t RTC_IRAM_ATTR process_ulp_events(void)
{    
    uint32_t wake_flags = WAKE_REASON_NONE;

    /* Read from the INACTIVE buffer to prevent race conditions */
    uint32_t active_buf = ulp_active_buffer & 0xFFFF;
    uint32_t* values = (active_buf == 0) ? &ulp_adc_readings_1 : &ulp_adc_readings_0;

    uint32_t local_buffer[ADC_READINGS];
    for (int i = 0; i < ADC_READINGS; i++) {
        local_buffer[i] = values[i] & 0xFFFF; // ULP stores data in lower 16 bits
    }

    /* ==========================================================
     * Battery Presence & Square Wave Filtering
     * ========================================================== */
    uint32_t bat_start_val = local_buffer[0];
    uint32_t bat_end_val   = local_buffer[16];
    uint32_t vbus_val      = local_buffer[15];

    // Delegate EVERYTHING to the battery module! It returns true if the state meaningfully changed.
    if (battery_submit_adc_readings(bat_start_val, bat_end_val, vbus_val)) {
        wake_flags |= WAKE_REASON_BATTERY;
    }

    // 2. Inhibit door logic if no battery is present AND the pulse is currently HIGH
    if (battery_get_presence() == BATTERY_PRESENCE_DISCONNECTED && (bat_start_val > 1500 || bat_end_val > 1500)) {
        // Throw away these ULP reads so they don't corrupt the EMA/MAD door baselines.
        return wake_flags; 
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
        
        int32_t s_val = local_buffer[ch] * SCALE_FACTOR; 

        if (!stats->initialized) {
            stats->ema = s_val;
            stats->mad = 5 * SCALE_FACTOR;
            stats->state = DOOR_CLOSED;
            stats->debounce_cnt = 0;
            stats->initialized = true;
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
        
        int32_t s_val = local_buffer[ch] * SCALE_FACTOR;

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
    while (1) {
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);

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

    /* 200ms ULP wakeup period (polling should run every 160ms) */
    //ulp_set_wakeup_period(0, 200000);

#if CONFIG_IDF_TARGET_ESP32
    rtc_gpio_isolate(GPIO_NUM_12);
    rtc_gpio_isolate(GPIO_NUM_15);
#endif

    esp_deep_sleep_disable_rom_logging();
}

static void start_ulp_program(void)
{
    /* Start the program */
    esp_err_t err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);
}

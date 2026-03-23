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

#define TAG "MUX_IO"

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

/* Declare our ULP variables */
extern uint32_t ulp_adc_readings;
extern uint32_t ulp_data_ready;

static TaskHandle_t ulp_task_handle = NULL;

#define NUM_DOOR_CHANNELS 14
#define SCALE_FACTOR 256  // Scales integers to give us "decimal" precision
#define ALPHA_SHIFT 3     // Equivalent to an alpha of 1/8 for smoothing

typedef enum {
    DOOR_CLOSED = 0,
    DOOR_OPEN = 1
} door_state_t;

/* State tracking for each channel. 
 * Must be in RTC_DATA_ATTR to survive deep sleep. */
typedef struct {
    int32_t ema;           // Scaled Exponential Moving Average
    int32_t mad;           // Scaled Mean Absolute Deviation
    int32_t open_baseline; // The EMA recorded right before the door opened
    door_state_t state;
    bool initialized;
} ch_stats_t;

static RTC_DATA_ATTR ch_stats_t ch_stats[NUM_DOOR_CHANNELS];

static void init_ulp_program(void);
static void start_ulp_program(void);
static bool process_ulp_events(uint32_t* values);

/* ==========================================================
 * ESP-IDF Managed Callback for ULP events while awake 
 * ========================================================== */
static void IRAM_ATTR ulp_isr_handler(void *arg)
{
    /* * Because we are using the official API, the ESP-IDF internal 
     * RTC dispatcher automatically clears the hardware flags and 
     * bypasses the ESP32 clock-domain bug! We just wake the task.
     */
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    vTaskNotifyGiveFromISR(ulp_task_handle, &xHigherPriorityTaskWoken);
    
    if (xHigherPriorityTaskWoken) {
        portYIELD_FROM_ISR();
    }
}

/* ==========================================================
 * FreeRTOS Task to handle the events off the ISR context
 * ========================================================== */
static void ulp_event_task(void *arg)
{
static door_state_t last_known_state[NUM_DOOR_CHANNELS] = {DOOR_CLOSED};

    while (1) {
        /* Block indefinitely (0 CPU cycles) until the ISR callback notifies us */
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
        if (process_ulp_events(&ulp_adc_readings)) {
            for (int i = 0; i < NUM_DOOR_CHANNELS; i++) {
                if (ch_stats[i].state != last_known_state[i]) {
                    // State changed!

                    ESP_LOGI(TAG, "Door %d | STATE: %s | Real ADC: %ld | MAD: %ld", 
                             i, 
                             ch_stats[i].state == DOOR_OPEN ? "OPEN" : "CLOSED",
                             ch_stats[i].ema / SCALE_FACTOR, 
                             ch_stats[i].mad / SCALE_FACTOR);
                    
                    esp_err_t err;
                    if (ch_stats[i].state == DOOR_OPEN) {
                        err = supervisor_submit_event_block(EVENT_DOOR_OPENED, (void*)i, pdMS_TO_TICKS(10));
                    } else {
                        err = supervisor_submit_event_block(EVENT_DOOR_CLOSED, (void*)i, pdMS_TO_TICKS(10));
                    }

                    // Only commit the last known state if we submitted the event, that way we can try submitting
                    // the event again.
                    if (err == ESP_OK) {
                        last_known_state[i] = ch_stats[i].state;
                    }
                }
            }
        }
    }
}


void mux_init()
{
    /* 1. Setup the FreeRTOS processing task */
    xTaskCreate(ulp_event_task, "ulp_event_task", 4096, NULL, 5, &ulp_task_handle);

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

    //process_ulp_events(wake_event_flags, wake_readings, wake_prev_readings);
}

bool RTC_IRAM_ATTR mux_wake_deep_sleep_early()
{
    return process_ulp_events(&ulp_adc_readings);
}

static bool process_ulp_events(uint32_t* values)
{    
    uint32_t local_buffer[16];
    memcpy(local_buffer, values, 16 * sizeof(uint32_t));

    // Let ULP know it can continue
    ulp_data_ready = 0;

    bool should_wake_main_cpu = false;

    // Only process channels 0 through 13
    for (int ch = 0; ch < NUM_DOOR_CHANNELS; ch++) {
        
        int32_t val = local_buffer[ch] & 0xFFFF;
        int32_t s_val = val * SCALE_FACTOR; // Scale up to preserve precision

        if (!ch_stats[ch].initialized) {
            ch_stats[ch].ema = s_val;
            ch_stats[ch].mad = 5 * SCALE_FACTOR; // Seed with a small assumed variance
            ch_stats[ch].state = DOOR_CLOSED;
            ch_stats[ch].initialized = true;
            continue;
        }

        if (ch_stats[ch].state == DOOR_CLOSED) {
            int32_t diff = s_val - ch_stats[ch].ema;
            int32_t abs_diff = (diff > 0) ? diff : -diff;

            // Threshold: Current EMA + (K * MAD). 
            // K=5 is roughly equivalent to 4 standard deviations.
            int32_t threshold = ch_stats[ch].mad * 5; 

            if (diff > threshold) {
                // SHARP INCREASE DETECTED: Door opened!
                ch_stats[ch].state = DOOR_OPEN;
                
                // Freeze the baseline so we know what "closed" looks like
                ch_stats[ch].open_baseline = ch_stats[ch].ema; 
                should_wake_main_cpu = true;
            } else {
                // Update EMA and MAD
                ch_stats[ch].ema += (diff >> ALPHA_SHIFT);
                ch_stats[ch].mad += ((abs_diff - ch_stats[ch].mad) >> ALPHA_SHIFT);

                // FIX: Raise the floor to ignore baseline ESP32 ADC noise!
                // Minimum ~30 ADC units of variance.
                if (ch_stats[ch].mad < (30 * SCALE_FACTOR)) {
                    ch_stats[ch].mad = 30 * SCALE_FACTOR;
                }            }
        } else {
            // DOOR IS OPEN: Wait for value to drop back near the stored baseline.
            // We consider it closed if it drops within 2 MADs of the old closed baseline.
            int32_t close_threshold = ch_stats[ch].open_baseline + (ch_stats[ch].mad * 2);

            if (s_val < close_threshold) {
                // VOLTAGE DROPPED: Door closed!
                ch_stats[ch].state = DOOR_CLOSED;
                
                // Fast-reset the EMA to the current lighting to sync immediately
                ch_stats[ch].ema = s_val; 
                should_wake_main_cpu = true;
            }
        }
    }
    
    return should_wake_main_cpu;
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


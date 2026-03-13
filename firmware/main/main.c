#include <stdio.h>
#include <stdbool.h>
#include <inttypes.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_sleep.h"
#include "driver/rtc_io.h"
#include "driver/gpio.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/sens_reg.h"
#include "esp_adc/adc_oneshot.h"
#include "ulp/mux_config.h"
#include "ulp_adc.h"
#include "ulp.h"          
#include "ulp_main.h"     
#include <driver/adc.h>
#include "esp_intr_alloc.h"
#include "soc/periph_defs.h"

/* Map our standard GPIOs to RTC logic */
#define MUX_PIN_A GPIO_NUM_32
#define MUX_PIN_B GPIO_NUM_33
#define MUX_PIN_C GPIO_NUM_27
#define MUX_PIN_D GPIO_NUM_26


extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

/* Declare our ULP arrays */
extern uint32_t ulp_adc_readings;
extern uint32_t ulp_prev_readings;
extern uint32_t ulp_event_flags;

static TaskHandle_t ulp_task_handle = NULL;

static void init_ulp_program(void);
static void start_ulp_program(void);
static void process_ulp_events(void);

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
    while (1) {
        /* Block indefinitely (0 CPU cycles) until the ISR callback notifies us */
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
        process_ulp_events();
    }
}

void app_main(void)
{
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();

    if (cause != ESP_SLEEP_WAKEUP_ULP) {
        printf("Initial Boot. Initializing ULP FSM...\n");
        init_ulp_program();
        start_ulp_program();
        printf("ULP EMA Tracking Started.\n");
    } else {
        printf("\n>>> WOKE UP FROM DEEP SLEEP VIA ULP <<<\n");
        /* Catch the event that woke us up immediately */
        process_ulp_events();
    }

    /* 1. Setup the FreeRTOS processing task */
    xTaskCreate(ulp_event_task, "ulp_event_task", 4096, NULL, 5, &ulp_task_handle);

    /* 2. Register the ULP callback using the official ESP-IDF API 
     * This attaches our handler safely behind the scenes without 
     * colliding with the Brownout detector.
     */
    ESP_ERROR_CHECK(ulp_isr_register(ulp_isr_handler, NULL));
    
    /* 3. Enable the specific ULP interrupt bit in the RTC controller so it fires */
    REG_SET_BIT(RTC_CNTL_INT_ENA_REG, RTC_CNTL_ULP_CP_INT_ENA);

    printf("\nMain core tracking for 10 seconds. Try opening/closing a door now!\n");    
    for (int iter = 0; iter < 100; iter++) {
        /* Print observation data (Notice we are no longer polling the events here!) */
        //printf("\n--- MUX Data (Iter %d/10) ---\n", iter + 1);
        uint32_t* reads = &ulp_adc_readings;
        uint32_t* emas  = &ulp_prev_readings;
        
        for (int ch = 0; ch < 16; ch++) {
            uint16_t val = reads[ch] & UINT16_MAX;
            uint16_t ema = emas[ch] & UINT16_MAX;
            //printf("CH %02d | RAW: %04d | EMA: %04d\n", ch, val, ema);
        }
        
        vTaskDelay(pdMS_TO_TICKS(160));
    }

    printf("\nGoing back to deep sleep. ULP assumes control...\n");
    
    /* Clean up the interrupt enable bit so we don't leak logic on the next wake cycle */
    REG_CLR_BIT(RTC_CNTL_INT_ENA_REG, RTC_CNTL_ULP_CP_INT_ENA);
    
    ESP_ERROR_CHECK(esp_sleep_enable_ulp_wakeup());
    esp_deep_sleep_start();
}

static void process_ulp_events(void)
{
    uint32_t* flags = &ulp_event_flags;
    uint32_t* reads = &ulp_adc_readings;
    uint32_t* emas  = &ulp_prev_readings;
    
    for (int i = 0; i < 16; i++) {
        uint16_t flag = flags[i] & UINT16_MAX;
        
        if (flag > 0) {
            uint16_t current_val = reads[i] & UINT16_MAX;
            uint16_t baseline    = emas[i] & UINT16_MAX;
            
            if (flag == 1) {
                printf("\n🔔 DOOR CH %02d OPENED!  (Spike: Baseline %d -> Read %d)\n", i, baseline, current_val);
            } else if (flag == 2) {
                printf("\n🚪 DOOR CH %02d CLOSED!  (Drop: Baseline %d -> Read %d)\n", i, baseline, current_val);
            }
            
            /* Clear the flag so it doesn't process again */
            flags[i] = 0; 
        }
    }

            printf("\n--- MUX Data  ---\n");
        
        for (int ch = 0; ch < 16; ch++) {
            uint16_t val = reads[ch] & UINT16_MAX;
            uint16_t ema = emas[ch] & UINT16_MAX;
            printf("CH %02d | RAW: %04d | EMA: %04d\n", ch, val, ema);
        }
}
static void init_ulp_program(void)
{
    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    ulp_adc_cfg_t cfg = {
        .adc_n    = MUX_ADC_UNIT,
        .channel  = MUX_ADC_CHANNEL,
        .width    = MUX_ADC_WIDTH,
        .atten    = MUX_ADC_ATTEN,
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

    /* 1-second ULP wakeup period */
    ulp_set_wakeup_period(0, 1000000);

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
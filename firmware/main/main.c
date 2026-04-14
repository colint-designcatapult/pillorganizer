#include <stdio.h>
#include <stdbool.h>
#include <memory.h>
#include <inttypes.h>
#include "esp_system.h"
#include "nvs_wrapper.h"
#include "supervisor.h"
#include "device_config.h"
#include "network.h"
#include "rtc.h"
#include <esp_err.h>
#include <esp_event.h>
#include "claim.h"
#include "shadow_state.h"
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>
#include "web_server.h"
#include "event_outbox.h"
#include "eng_cli.h"
#include <esp_log.h>
#include "sdkconfig.h"

#if !CONFIG_EMULATOR_MODE
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
#include "pill_pins.h"
#include "i2c_dev.h"
#include "ledc.h"
#include <esp_private/sar_periph_ctrl.h>
#include "battery.h"
#endif

#define TAG "MAIN"

#if !CONFIG_EMULATOR_MODE

void RTC_IRAM_ATTR esp_wake_deep_sleep(void)
{ 
    if (mux_wake_deep_sleep_early()) {
        esp_default_wake_deep_sleep();
    } else {
        esp_deep_sleep_start();
    }
}

static void app_fresh_boot()
{
    // First boot reset, full system init
    mux_fresh_boot();
}

static void app_wake_deep_sleep()
{
    // Init system from deep sleep
    mux_wake_deep_sleep();
}

SemaphoreHandle_t s_button_press_sem;

static void IRAM_ATTR reset_btn_isr_handler(void* arg)
{
    // 1. Immediately disable the interrupt to prevent bounce spam
    gpio_intr_disable(RESET_BTN);

    // 2. Wake up the button task
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    xSemaphoreGiveFromISR(s_button_press_sem, &xHigherPriorityTaskWoken);
    
    // 3. Yield to the higher priority task if needed
    if (xHigherPriorityTaskWoken == pdTRUE) {
        portYIELD_FROM_ISR();
    }
}

void reset_button_task(void *pvParameters)
{
    while (1) {
        // Sleep until the ISR gives the semaphore (button is pressed)
        if (xSemaphoreTake(s_button_press_sem, portMAX_DELAY)) {
            
            // Wait 50ms to let the physical button contacts settle (debounce)
            vTaskDelay(pdMS_TO_TICKS(50)); 
            
            uint32_t hold_time_ms = 0;
            bool triggered_1s = false;
            bool triggered_3s = false;
            bool triggered_10s = false;

            // Loop continuously AS LONG AS the button is held down (0 = pressed)
            while (gpio_get_level(RESET_BTN) == 0) {
                
                vTaskDelay(pdMS_TO_TICKS(100)); // Step forward in 100ms chunks
                hold_time_ms += 100;

                // --- REAL TIME FEEDBACK LOGIC ---
                if (hold_time_ms >= 1000 && !triggered_1s) {
                    ESP_LOGI(TAG, "Reset held for 1 second");
                    triggered_1s = true;
                    ledc_set_task(LED_BLINK, (led_task_param_t) {
                        .blink = {
                            .red = 0,
                            .green = LED_ALL_DOORS
                        }
                    }, 0);
                }
                
                if (hold_time_ms >= 3000 && !triggered_3s) {
                    ESP_LOGI(TAG, "Reset held for 3 seconds");
                    triggered_3s = true;
                    ledc_set_task(LED_BLINK, (led_task_param_t) {
                        .blink = {
                            .red = LED_ALL_DOORS,
                            .green = LED_ALL_DOORS
                        }
                    }, 0);
                }

                if (hold_time_ms >= 10000 && !triggered_10s) {
                    ESP_LOGI(TAG, "Reset held for 10 seconds");
                    triggered_10s = true;
                    ledc_set_task(LED_BLINK, (led_task_param_t) {
                        .blink = {
                            .red = LED_ALL_DOORS,
                            .green = 0
                        }
                    }, 0);
                }
            }

            // --- BUTTON RELEASED: FINAL ACTION LOGIC ---
            if (triggered_10s) {
                // Factory reset
                supervisor_factory_reset();
            } else if (triggered_3s) {
                // Reset Wi-Fi
                supervisor_reset_wifi();
            } else if (triggered_1s) {
                // Reboot
                esp_restart();
            } else {
                ESP_LOGI(TAG, "Reset released before any threshold");
                // Notify that LED effect complete so supervisor knows to reset LED state
                ESP_ERROR_CHECK(supervisor_submit_event(EVENT_LED_EFFECT_COMPLETE));
            }

            // Clean up and re-enable the interrupt for the next press
            xSemaphoreTake(s_button_press_sem, 0); // Flush any accidental bounce tokens
            gpio_intr_enable(RESET_BTN);         // Turn the interrupt back on
        }
    }
}

static QueueHandle_t gpio_evt_queue = NULL;

static void IRAM_ATTR gpio_isr_handler(void* arg)
{
    uint32_t gpio_num = (uint32_t) arg;
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    BaseType_t send_result;

    // Send the GPIO number that triggered the interrupt to the queue
    send_result = xQueueSendFromISR(gpio_evt_queue, &gpio_num, &xHigherPriorityTaskWoken);

    // If a higher-priority task was unblocked, request a context switch now.
    if ((send_result == pdPASS) && (xHigherPriorityTaskWoken == pdTRUE)) {
        portYIELD_FROM_ISR();
    }
}

void gpio_task(void *pvParameters)
{
    gpio_num_t io_num;
    for(;;) {
        // Wait indefinitely for an item to appear in the queue
        if(xQueueReceive(gpio_evt_queue, &io_num, portMAX_DELAY)) {
            
            // Read the current state of the pin
            int level = gpio_get_level(io_num);
            
            if (io_num == BAT_PGOOD_PIN) {
                battery_submit_pgood_pin(!((bool) level));
            } else if (io_num == BAT_CHARGE_PIN) {
                battery_submit_charge_pin(!((bool) level));
            }
        }
    }
}

static void app_init_gpio(void)
{
    gpio_config_t io_conf = { 0 };

    gpio_evt_queue = xQueueCreate(10, sizeof(uint32_t));
    //start gpio task pinned to PRO CPU to prevent Core 1 RTC bus limitations
    xTaskCreatePinnedToCore(gpio_task, "gpio_task", 2048, NULL, 10, NULL, 0);

	// BAT_PGOOD_PIN
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_ANYEDGE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << BAT_PGOOD_PIN);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_ENABLE;  
    gpio_config(&io_conf);

	// BAT_CHARGE_PIN
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_ANYEDGE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << BAT_CHARGE_PIN);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_ENABLE;  
    gpio_config(&io_conf);

    gpio_install_isr_service(ESP_INTR_FLAG_IRAM); 

    // Hook the ISR handler for specific gpio pins
    gpio_isr_handler_add(BAT_PGOOD_PIN, gpio_isr_handler, (void*) BAT_PGOOD_PIN);
    gpio_isr_handler_add(BAT_CHARGE_PIN, gpio_isr_handler, (void*) BAT_CHARGE_PIN);

    // IS31 CS
    memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << IS31_CS);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;  
    gpio_config(&io_conf);
    // Hold this at high
    gpio_set_level(IS31_CS, 1);


    // Prevent GPIO36 voltage glitch
    // WORKAROUND for ESP32 Errata 3.11
    // See issue #136
    sar_periph_ctrl_adc_oneshot_power_acquire();

    s_button_press_sem = xSemaphoreCreateBinary();
    xTaskCreate(reset_button_task, "reset_button_task", 2048, NULL, 10, NULL);

    // Configure the pin to fire ONLY on the press (Falling Edge)
    memset(&io_conf, 0, sizeof(io_conf));
    io_conf.intr_type = GPIO_INTR_NEGEDGE;          // <-- Fire on press only
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << RESET_BTN);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;  
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;       
    gpio_config(&io_conf);

    // Attach the interrupt
    gpio_isr_handler_add(RESET_BTN, reset_btn_isr_handler, NULL);
}

static void app_init_hw()
{
    //
    // HARDWARE INITIALIZATION
    // 

    // Initialize the MUX first so we receive bin door events as early as possible
    mux_init();

    // Init GPIO
    app_init_gpio();

    // Initialize i2c master
    i2c_master_init(I2C_FREQ);

    // Initialize LED controller
    ledc_init();

    // Initialize battery 
    battery_init();
}

#endif /* !CONFIG_EMULATOR_MODE */


void app_main(void)
{
    // Initialize non-volatile storage (flash storage)
    init_nvs();

    // Initialize event outbox early so events can be recorded before mux_io starts
    event_outbox_init();

    // Initialize event loop
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    // Initialize the supervisor
    supervisor_init();

#if !CONFIG_EMULATOR_MODE
    // Perform early initialization depending on if this is a fresh boot or wake from deep sleep
    esp_reset_reason_t reset_reason = esp_reset_reason();
    if (reset_reason == ESP_RST_DEEPSLEEP) {
        ESP_LOGI(TAG, "Waking from deep sleep");
        app_wake_deep_sleep();
    } else {
        ESP_LOGI(TAG, "Cold boot");
        app_fresh_boot();
    }

    // Initialize hardware peripherals
    app_init_hw();

    ESP_LOGI(TAG, "Hardware initialized");
#else
    ESP_LOGI(TAG, "=== QEMU Emulator Mode ===");
#endif

    // Initialize device configuration 
    devcfg_init();

    // Initialize RTC
    app_rtc_init();

    // Initialize claim subsystem
    claim_init();

    // Initialize networking
    network_init();

    // Initialize the web server for testing/engineering
    web_server_init();

    // Start the engineering CLI (UART console)
    eng_cli_init();

    // Hand off business logic to the supervisor
    supervisor_run();

#if !CONFIG_EMULATOR_MODE
    // If we've reached here, there is nothing more to do
    // Go to sleep
    esp_deep_sleep_start();
#endif
}


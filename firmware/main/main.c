#include <stdio.h>
#include <stdbool.h>
#include <memory.h>
#include <inttypes.h>
#include "esp_sleep.h"
#include "esp_system.h"
#include "driver/rtc_io.h"
#include "driver/gpio.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/sens_reg.h"
#include "esp_adc/adc_oneshot.h"
#include "ulp/mux_config.h"
#include "mux_io.h"
#include "esp_intr_alloc.h"
#include "soc/periph_defs.h"
#include "nvs_wrapper.h"
#include "pill_pins.h"
#include "i2c_dev.h"
#include "ledc.h"
#include "supervisor.h"
#include "device_config.h"
#include "network.h"
#include "rtc.h"
#include <esp_err.h>
#include <esp_event.h>
#include "claim.h"

#define TAG "MAIN"

void RTC_IRAM_ATTR esp_wake_deep_sleep(void)
{ 
    esp_default_wake_deep_sleep();

    // Code that runs immediately after deep sleep wake
    mux_wake_deep_sleep_early();
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

static void app_init_gpio(void)
{
    gpio_config_t io_conf = { 0 };


    // TEST POINTS
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = ((1ULL << TP47)|(1ULL << VBAT_MEAS_PIN)|(1ULL << TP18));
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;  
    gpio_config(&io_conf);

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
	io_conf.intr_type = GPIO_INTR_POSEDGE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << BAT_CHARGE_PIN);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_ENABLE;  
    gpio_config(&io_conf);

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

    // Reset Button
	memset(&io_conf, 0, sizeof(io_conf));
	io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_INPUT;
    io_conf.pin_bit_mask = (1ULL << RESET_BTN);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;  
    gpio_config(&io_conf);

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
}

void app_main(void)
{
    // Initialize non-volatile storage (flash storage)
    init_nvs();

    // Initialize event loop
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    // Initialize the supervisor
    supervisor_init();

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

    // Initialize device configuration 
    devcfg_init();

    // Initialize RTC
    app_rtc_init();

    // Initialize claim subsystem
    claim_init();

    // Initialize networking
    network_init();

    // Hand off business logic to the supervisor
    supervisor_run();

    // If we've reached here, there is nothing more to do
    // Go to sleep
    esp_deep_sleep_start();
}


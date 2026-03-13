#include <stdio.h>
#include <stdbool.h>
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

void app_main(void)
{
    // Perform early initialization depending on if this is a fresh boot or wake from deep sleep
    esp_reset_reason_t reset_reason = esp_reset_reason();
    if (reset_reason == ESP_RST_DEEPSLEEP) {
        app_wake_deep_sleep();
    } else {
        app_fresh_boot();
    }
    
    //
    // HARDWARE INITIALIZATION
    // 

    // Initialize the MUX so we receive bin door events as early as possible
    mux_init();

    // 

    //mux_prep_deep_sleep();
    //esp_deep_sleep_start();
}


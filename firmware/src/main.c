#include <stdio.h>
#include <string.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"

#include "esp_system.h"
#include "esp_spi_flash.h"
#include <esp_wifi.h>
#include <esp_netif.h>
#include "esp_log.h"
#include <esp_ota_ops.h>
#include "util.h"

#include "driver/ledc.h"
#include "driver/adc.h"
#include "driver/gpio.h"
#include "driver/touch_sensor.h"
#include "esp_sleep.h"

#include "wifi_provisioner.h"
#include "pill_gpio.h"
#include "pill_state.h"
#include "nvs_wrapper.h"
#include "rtc_sntp.h"

#include "IS31FL3730.h"
#include "i2c_dev.h"

#include "config.h"
#include "engineering.h"
#include "event.h"
#include "esp_console.h"
#include "wifi.h"
#include "ble.h"


#define TAG "MAIN"

const int OTA_START_EVENT = BIT0;

static void heartbeat_task(void* arg) {
    for(;;) {
        for(int i = 0; i < FIRMWARE_REVISION; i++) {
            gpio_set_level(HEART_LED_PIN, 1);
            vTaskDelay(pdMS_TO_TICKS(100));
            gpio_set_level(HEART_LED_PIN, 0);
            vTaskDelay(pdMS_TO_TICKS(300));
        }

        vTaskDelay(pdMS_TO_TICKS(1000));
        esp_task_wdt_reset();
    }
}

static int read_command(int argc, char **argv)
{
    engineering_print_samples();
    return 0;
}

static int logs_command(int argc, char **argv)
{
    if(argc == 2) {
        if(strcmp(argv[1], "on") == 0) {
            engineering_logs_on();
            return 0;
        } else if(strcmp(argv[1], "off") == 0) {
            engineering_logs_off();
            return 0;
        }
    }
    puts("Usage: logs [on|off]\n");
    return 0;
}

static int ip_command(int argc, char **argv)
{
    engineering_print_ids();
    return 0;
}


void app_main(void)
{

    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t ota_state;
    if (esp_ota_get_state_partition(running, &ota_state) == ESP_OK) {
        if (ota_state == ESP_OTA_IMG_PENDING_VERIFY) {
            // run diagnostic function ...
            bool diagnostic_is_ok = true;
            if (diagnostic_is_ok) {
                ESP_LOGI(TAG, "Diagnostics completed successfully! Continuing execution ...");
                esp_ota_mark_app_valid_cancel_rollback();
            } else {
                ESP_LOGE(TAG, "Diagnostics failed! Start rollback to the previous version ...");
                esp_ota_mark_app_invalid_rollback_and_reboot();
            }
        }
    }


    ESP_LOGI(TAG, "JCTPillOrganizer firmware version %d_%s %s loaded, board rev %d", FIRMWARE_REVISION, FIRMWARE_BUILD, FIRMWARE_DATE, BOARD_REV);

    init_nvs();
    on_init();

    create_task_with_watchdog(&adc_read_task, "ADC Poll Task", 4096, NULL, 1);
    create_task_with_watchdog(&heartbeat_task, "Heartbeat task", 2048, NULL, 1);

    esp_console_dev_uart_config_t uart_config = ESP_CONSOLE_DEV_UART_CONFIG_DEFAULT();
    esp_console_repl_config_t rc = ESP_CONSOLE_REPL_CONFIG_DEFAULT();
    rc.prompt = "pill>";
    esp_console_repl_t* o;

    esp_console_cmd_t read_cmd = {
        .command = "r",
        .help = "Read all photoresistor values from the MUX",
        .func = &read_command
    };

    esp_console_cmd_t logs_cmd = {
        .command = "logs",
        .help = "Turns logging on or off.",
        .func = &logs_command,
    };

    esp_console_cmd_t ip_cmd = {
        .command = "ip",
        .help = "Print IP address/serial number",
        .func = &ip_command,
    };

    esp_console_new_repl_uart(&uart_config, &rc, &o);
    esp_console_cmd_register(&read_cmd);
    esp_console_cmd_register(&logs_cmd);
    esp_console_cmd_register(&ip_cmd);
    //engineering_logs_off();

    ble_init();
    wifi_init(); 

    esp_console_start_repl(o);

    // todo: remove this
    // replace with power management
    while(true) {
        vTaskDelay(pdMS_TO_TICKS(1000));
        esp_task_wdt_reset();
    }
}
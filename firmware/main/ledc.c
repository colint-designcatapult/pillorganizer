#include "ledc.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "IS31FL3730.h"
#include "i2c_dev.h"

void led_task(void*);

void ledc_init()
{
    // Initialize the LED driver
    IS31FL3730_init();
    IS31FL3730_set_brightness(127);

    xTaskCreate(led_task, "LED Task", 4096, NULL, 1, NULL);   
}

void led_task(void* arg)
{

    i2c_write_register(ISSI_ADDR, MWFU_G_PM, 0xff);
    i2c_write_register(ISSI_ADDR, MWFU_G_AM, 0xff);
    i2c_write_register(ISSI_ADDR, TRS_G_PM, 0xff);                            
    i2c_write_register(ISSI_ADDR, TRS_G_AM, 0xff);
    i2c_write_register(ISSI_ADDR, MWFU_R_PM, 0x00);
    i2c_write_register(ISSI_ADDR, MWFU_R_AM, 0x00);
    i2c_write_register(ISSI_ADDR, TRS_R_PM, 0x00);                            
    i2c_write_register(ISSI_ADDR, TRS_R_AM, 0x00);
    i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   

    int8_t step = 1;
    uint8_t breath = 0;

    for(;;) {

        if (breath >= 64) {
            step = -1;
        } else if (breath <= 0) {
            step = 1;
        }
        
        breath += step;

        IS31FL3730_set_brightness(breath);
        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
        vTaskDelay(pdMS_TO_TICKS(20));
    }
}
#include "ledc.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "IS31FL3730.h"
#include "i2c_dev.h"
#include <stdatomic.h>

static atomic_ullong s_led_task = 0; 
static atomic_ullong s_led_param = 0;
static atomic_bool s_reset = true;

void led_task(void*);

void ledc_init()
{
    // Initialize the LED driver
    IS31FL3730_init();
    IS31FL3730_set_brightness(127);

    xTaskCreate(led_task, "LED Task", 4096, NULL, 1, NULL);   
}

void ledc_set_task(led_task_t task, led_task_param_t param)
{
    atomic_store_explicit(&s_led_task, task, memory_order_relaxed);
    atomic_store_explicit(&s_led_param, param.raw, memory_order_relaxed);
    atomic_store_explicit(&s_reset, true, memory_order_relaxed);
}

void led_task(void* arg)
{
    int8_t step = 1;
    uint32_t step_ctr = 0;

    // Initialize to safe defaults
    led_task_param_t last_param = {0};
    led_task_t last_task = LED_IDLE;
    led_task_t prev_task = LED_IDLE; // Keep track of the previous task to prevent unwanted resets

    for(;;) {
        led_task_t task = (led_task_t)atomic_load_explicit(&s_led_task, memory_order_relaxed);
        led_task_param_t param;
        param.raw = atomic_load_explicit(&s_led_param, memory_order_relaxed);

        if (atomic_load_explicit(&s_reset, memory_order_relaxed)) {
            bool task_changed = (task != prev_task);

            if (task != LED_BLINK_AND_ROLLBACK) {
                last_task = task;
                last_param = param;
            }

            // Only reset the animation step counter if we are actually changing tasks.
            if (task_changed || task != LED_PROGRESS) {
                step_ctr = 0;
            }
            prev_task = task;
            
            if(task == LED_IDLE) {
                i2c_write_register(ISSI_ADDR, MWFU_G_PM, 0x00);
                i2c_write_register(ISSI_ADDR, MWFU_G_AM, 0x00);
                i2c_write_register(ISSI_ADDR, TRS_G_PM, 0x00);                            
                i2c_write_register(ISSI_ADDR, TRS_G_AM, 0x00);
                i2c_write_register(ISSI_ADDR, MWFU_R_PM, 0x00);
                i2c_write_register(ISSI_ADDR, MWFU_R_AM, 0x00);
                i2c_write_register(ISSI_ADDR, TRS_R_PM, 0x00);                            
                i2c_write_register(ISSI_ADDR, TRS_R_AM, 0x00);
                IS31FL3730_set_brightness(0);
                i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
            } else if (task == LED_BREATHE || task == LED_BLINK_AND_ROLLBACK) {
                step = 1;
                i2c_write_register(ISSI_ADDR, MWFU_G_PM, param.breathe.green);
                i2c_write_register(ISSI_ADDR, MWFU_G_AM, param.breathe.green);
                i2c_write_register(ISSI_ADDR, TRS_G_PM, param.breathe.green);                            
                i2c_write_register(ISSI_ADDR, TRS_G_AM, param.breathe.green);
                i2c_write_register(ISSI_ADDR, MWFU_R_PM, param.breathe.red);
                i2c_write_register(ISSI_ADDR, MWFU_R_AM, param.breathe.red);
                i2c_write_register(ISSI_ADDR, TRS_R_PM, param.breathe.red);                            
                i2c_write_register(ISSI_ADDR, TRS_R_AM, param.breathe.red);
                i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
            } else if (task == LED_PROGRESS) {
                // Ensure global brightness is set for solid LEDs
                IS31FL3730_set_brightness(127);
            }

            atomic_store_explicit(&s_reset, false, memory_order_relaxed);
        }

        if (task == LED_BREATHE) {
            if (step_ctr >= 64) {
                step = -1;
            } else if (step_ctr <= 0) {
                step = 1;
            }
            
            step_ctr += step;

            IS31FL3730_set_brightness((uint8_t)step_ctr);
            i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   

        } else if (task == LED_BLINK_AND_ROLLBACK) {
            
            // Toggle logic based on your 50-tick intervals
            if(step_ctr % 25 == 0) {
                uint8_t brightness = ((step_ctr / 25) % 2 == 0) ? 127 : 0;
                IS31FL3730_set_brightness(brightness);
                i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
            }

            step_ctr++;

            if(step_ctr == 400) {
                ledc_set_task(last_task, last_param);
            }
            
        } else if (task == LED_PROGRESS) {
            // 50 ticks = 1 second. 
            uint32_t target_tick = param.progress.progress * 50;

            // Catch up to target progress
            if (step_ctr < target_tick) {
                step_ctr++;
            } else if (step_ctr > target_tick) {
                step_ctr--; 
            }

            // Calculate how many days should be currently lit based on the step_ctr
            // Day 1 snaps on at tick 1, Day 2 snaps on at tick 51, etc.
            uint8_t active_days = (step_ctr > 0) ? ((step_ctr - 1) / 50) + 1 : 0;

            uint8_t mwfu_mask = 0;
            uint8_t trs_mask = 0;

            // Map standard linear index 0-6 to MWFU and TRS bits
            for (int i = 0; i < 7; i++) {
                if (i < active_days) {
                    switch(i) {
                        case 0: mwfu_mask |= (1 << 0); break; // Monday    (MWFU bit 0)
                        case 1: trs_mask  |= (1 << 0); break; // Tuesday   (TRS  bit 0)
                        case 2: mwfu_mask |= (1 << 1); break; // Wednesday (MWFU bit 1)
                        case 3: trs_mask  |= (1 << 1); break; // Thursday  (TRS  bit 1)
                        case 4: mwfu_mask |= (1 << 2); break; // Friday    (MWFU bit 2)
                        case 5: trs_mask  |= (1 << 2); break; // Saturday  (TRS  bit 2)
                        case 6: mwfu_mask |= (1 << 3); break; // Sunday    (MWFU bit 3)
                    }
                }
            }

            // Apply the bitwise masks along with the requested base colors
            i2c_write_register(ISSI_ADDR, MWFU_G_PM, mwfu_mask & param.progress.green);
            i2c_write_register(ISSI_ADDR, MWFU_G_AM, mwfu_mask & param.progress.green);
            i2c_write_register(ISSI_ADDR, TRS_G_PM,  trs_mask  & param.progress.green);
            i2c_write_register(ISSI_ADDR, TRS_G_AM,  trs_mask  & param.progress.green);
            
            i2c_write_register(ISSI_ADDR, MWFU_R_PM, mwfu_mask & param.progress.red);
            i2c_write_register(ISSI_ADDR, MWFU_R_AM, mwfu_mask & param.progress.red);
            i2c_write_register(ISSI_ADDR, TRS_R_PM,  trs_mask  & param.progress.red);
            i2c_write_register(ISSI_ADDR, TRS_R_AM,  trs_mask  & param.progress.red);
            
            i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
        }

        vTaskDelay(pdMS_TO_TICKS(20));
    }
}
#include "ledc.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "IS31FL3730.h"
#include "i2c_dev.h"
#include <stdatomic.h>
#include "supervisor.h"

// Define magic numbers for better readability
#define PROGRESS_TICKS_PER_STEP 50
#define BLINK_INTERVAL_TICKS    12
#define MAX_BREATHE_STEPS       127
#define TASK_TICK_RATE_MS       20

static atomic_uint_fast32_t s_led_task = ATOMIC_VAR_INIT(0); 
static atomic_ullong s_led_param = ATOMIC_VAR_INIT(0);
static atomic_uint_fast32_t s_led_duration = ATOMIC_VAR_INIT(0);
static atomic_bool s_reset = ATOMIC_VAR_INIT(true);

void led_task(void* arg);

void ledc_init(void)
{
    // Initialize the LED driver
    IS31FL3730_init();
    IS31FL3730_set_brightness(MAX_BREATHE_STEPS);

    xTaskCreate(led_task, "LED Task", 4096, NULL, 1, NULL);   
}

void ledc_set_task(led_task_t task, led_task_param_t param, uint32_t duration_ms)
{
    atomic_store_explicit(&s_led_task, task, memory_order_relaxed);
    atomic_store_explicit(&s_led_param, param.raw, memory_order_relaxed);
    atomic_store_explicit(&s_led_duration, duration_ms, memory_order_relaxed);
    
    // Use memory_order_release to ensure the parameter writes finish before the flag flips
    atomic_store_explicit(&s_reset, true, memory_order_release); 
}

static void apply_led_bitfields(uint16_t red, uint16_t green)
{
    uint8_t r_mwfu_pm = 0, r_mwfu_am = 0, r_trs_pm = 0, r_trs_am = 0;
    uint8_t g_mwfu_pm = 0, g_mwfu_am = 0, g_trs_pm = 0, g_trs_am = 0;

    for (int i = 0; i < 14; i++) {
        int day = i / 2;
        bool is_am = i % 2; // Preserved original hardware mapping
        uint8_t bit = 1 << (day / 2);
        bool is_mwfu = (day % 2 == 0);

        if ((red >> i) & 1) {
            if (is_mwfu) {
                if (is_am) r_mwfu_am |= bit; else r_mwfu_pm |= bit;
            } else {
                if (is_am) r_trs_am |= bit; else r_trs_pm |= bit;
            }
        }

        if ((green >> i) & 1) {
            if (is_mwfu) {
                if (is_am) g_mwfu_am |= bit; else g_mwfu_pm |= bit;
            } else {
                if (is_am) g_trs_am |= bit; else g_trs_pm |= bit;
            }
        }
    }

    i2c_write_register(ISSI_ADDR, MWFU_G_PM, g_mwfu_pm);
    i2c_write_register(ISSI_ADDR, MWFU_G_AM, g_mwfu_am);
    i2c_write_register(ISSI_ADDR, TRS_G_PM, g_trs_pm);                            
    i2c_write_register(ISSI_ADDR, TRS_G_AM, g_trs_am);
    i2c_write_register(ISSI_ADDR, MWFU_R_PM, r_mwfu_pm);
    i2c_write_register(ISSI_ADDR, MWFU_R_AM, r_mwfu_am);
    i2c_write_register(ISSI_ADDR, TRS_R_PM, r_trs_pm);                            
    i2c_write_register(ISSI_ADDR, TRS_R_AM, r_trs_am);
}

void led_task(void* arg)
{
    led_task_t prev_task = LED_IDLE; // Keep track of the previous state
    int8_t step = 1;
    uint32_t step_ctr = 0;
    uint32_t duration_ticks = 0;
    uint32_t elapsed_ticks = 0;

    for(;;) {
        // 1. Thread-safe read and reset of the flag using atomic_exchange
        bool trigger_reset = atomic_exchange_explicit(&s_reset, false, memory_order_acquire);
        
        led_task_t task = (led_task_t)atomic_load_explicit(&s_led_task, memory_order_relaxed);
        led_task_param_t param;
        param.raw = atomic_load_explicit(&s_led_param, memory_order_relaxed);
        uint32_t duration_ms = atomic_load_explicit(&s_led_duration, memory_order_relaxed);

        // 2. Handle Task Transitions & Resets
        if (trigger_reset) {
            elapsed_ticks = 0;
            duration_ticks = (duration_ms == 0) ? 0 : (duration_ms / TASK_TICK_RATE_MS);
            
            // CRITICAL FIX: Only reset the step counter if we are NOT continuing a PROGRESS effect
            if (!(task == LED_PROGRESS && prev_task == LED_PROGRESS)) {
                step_ctr = 0;
            }

            // Task Initialization 
            switch (task) {
                case LED_IDLE:
                    apply_led_bitfields(0, 0);
                    IS31FL3730_set_brightness(0);
                    i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
                    break;
                case LED_BREATHE:
                    step = 1;
                    apply_led_bitfields(param.breathe.red, param.breathe.green);
                    i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
                    break;
                case LED_BLINK:
                case LED_PROGRESS:
                    IS31FL3730_set_brightness(MAX_BREATHE_STEPS);
                    if (task == LED_BLINK) {
                        apply_led_bitfields(param.blink.red, param.blink.green);
                        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
                    }
                    break;
                default:
                    break;
            }
            
            prev_task = task; // Save for the next iteration
        }

        // 3. Handle Duration Expiration
        if (task != LED_IDLE && duration_ticks > 0) {
            elapsed_ticks++;
            if (elapsed_ticks >= duration_ticks) {
                ledc_set_task(LED_IDLE, (led_task_param_t){0}, 0);
                supervisor_submit_event(EVENT_LED_EFFECT_COMPLETE);
                continue; // Skip the tick logic and re-evaluate state immediately
            }
        }

        // 4. Tick Animation Logic (Using a switch for readability)
        switch (task) {
            case LED_BREATHE:
                if (step_ctr >= MAX_BREATHE_STEPS) step = -1;
                else if (step_ctr == 0) step = 1;
                
                step_ctr += step;
                IS31FL3730_set_brightness((uint8_t)step_ctr);
                i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
                break;

            case LED_BLINK:
                if (step_ctr % BLINK_INTERVAL_TICKS == 0) {
                    bool on = (step_ctr / BLINK_INTERVAL_TICKS) % 2 == 0;
                    apply_led_bitfields(on ? param.blink.red : 0, on ? param.blink.green : 0);
                    i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
                }
                step_ctr++;
                break;

            case LED_PROGRESS: {
                uint32_t target_tick = param.progress.progress * PROGRESS_TICKS_PER_STEP;

                // Animate towards the target (Handles both increasing AND decreasing progress gracefully)
                if (step_ctr < target_tick) step_ctr++;
                else if (step_ctr > target_tick) step_ctr--; 

                uint8_t active_days = (step_ctr > 0) ? ((step_ctr - 1) / PROGRESS_TICKS_PER_STEP) + 1 : 0;
                uint16_t red_mask = 0, green_mask = 0;

                for (int i = 0; i < 7; i++) {
                    if (i < active_days) {
                        red_mask |= (0x3 << (i * 2));
                        green_mask |= (0x3 << (i * 2));
                    }
                }

                apply_led_bitfields(red_mask & param.progress.red, green_mask & param.progress.green);
                i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
                break;
            }
            
            case LED_IDLE:
            default:
                break;
        }

        vTaskDelay(pdMS_TO_TICKS(TASK_TICK_RATE_MS));
    }
}
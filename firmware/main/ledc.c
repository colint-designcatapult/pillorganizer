#include "ledc.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "IS31FL3730.h"
#include "i2c_dev.h"
#include <stdatomic.h>
#include "supervisor.h"
#include "string.h"
#include <stdlib.h>
#include <string.h>

// Define magic numbers for better readability
#define PROGRESS_TICKS_PER_STEP 50
#define BLINK_INTERVAL_TICKS    12
#define MAX_BREATHE_STEPS       127
#define TASK_TICK_RATE_MS       20
#define FIREWORK_TICKS_PER_RING 3

#define FADE_IN_DURATION_MS     500
#define FADE_IN_TICKS           (FADE_IN_DURATION_MS / TASK_TICK_RATE_MS)

// Atomic stores for the background "Idle" task
static atomic_uint_fast32_t s_led_idle_task = ATOMIC_VAR_INIT(LED_IDLE); 
static atomic_ullong s_led_idle_param = ATOMIC_VAR_INIT(0);

// Atomic stores for the currently running task
static atomic_uint_fast32_t s_led_task = ATOMIC_VAR_INIT(LED_IDLE); 
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
    // 1. Check if the new active state perfectly matches the current active state
    led_task_t current_task = (led_task_t)atomic_load_explicit(&s_led_task, memory_order_relaxed);
    uint64_t current_param = atomic_load_explicit(&s_led_param, memory_order_relaxed);
    uint32_t current_duration = atomic_load_explicit(&s_led_duration, memory_order_relaxed);

    if (current_task == task && current_param == param.raw && current_duration == duration_ms) {
        return; // Task is already running with these parameters, skip reset
    }

    // 2. State is different, proceed with the update
    atomic_store_explicit(&s_led_task, task, memory_order_relaxed);
    atomic_store_explicit(&s_led_param, param.raw, memory_order_relaxed);
    atomic_store_explicit(&s_led_duration, duration_ms, memory_order_relaxed);
    
    // Use memory_order_release to ensure the parameter writes finish before the flag flips
    atomic_store_explicit(&s_reset, true, memory_order_release); 
}

void ledc_set_idle_task(led_task_t task, led_task_param_t param)
{
    // 1. Check if the new state perfectly matches the current idle state
    led_task_t current_idle_task = (led_task_t)atomic_load_explicit(&s_led_idle_task, memory_order_relaxed);
    uint64_t current_idle_param = atomic_load_explicit(&s_led_idle_param, memory_order_relaxed);

    if (current_idle_task == task && current_idle_param == param.raw) {
        return; // State hasn't changed, bail out to prevent resetting the animation
    }

    // 2. State is different, proceed with the update
    atomic_store_explicit(&s_led_idle_task, task, memory_order_relaxed);
    atomic_store_explicit(&s_led_idle_param, param.raw, memory_order_relaxed);

    // If there is no timed effect currently running, update the live state immediately
    if (atomic_load_explicit(&s_led_duration, memory_order_relaxed) == 0) {
        ledc_set_task(task, param, 0);
    }
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
    led_task_t prev_task = LED_IDLE; 
    int8_t step = 1;
    uint32_t step_ctr = 0;
    uint32_t duration_ticks = 0;
    uint32_t elapsed_ticks = 0;
    
    // NEW: Track the fade-in state
    uint32_t fade_ticks_remaining = 0;

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

            // NEW: If this reset was triggered by an EXTERNAL call (not our internal fade logic),
            // cancel any ongoing fade-in so the new animation gets full brightness immediately.
            if (fade_ticks_remaining != FADE_IN_TICKS) {
                fade_ticks_remaining = 0;
            }

            // Task Initialization 
            switch (task) {
                case LED_IDLE:
                    apply_led_bitfields(0, 0); // Completely off
                    IS31FL3730_set_brightness(0);
                    i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
                    break;
                case LED_BREATHE:
                    step = 1;
                    apply_led_bitfields(param.breathe.red, param.breathe.green);
                    i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);   
                    break;
                case LED_DEVICE_STATE:
                case LED_BLINK:
                case LED_PROGRESS:
                    IS31FL3730_set_brightness(MAX_BREATHE_STEPS);
                    if (task == LED_BLINK) {
                        apply_led_bitfields(param.blink.red, param.blink.green);
                        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
                    } else if (task == LED_DEVICE_STATE) {
                        apply_led_bitfields(param.device_state.red, param.device_state.green);
                        i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
                    }
                    break;
                case LED_FIREWORK:
                    IS31FL3730_set_brightness(MAX_BREATHE_STEPS);
                    apply_led_bitfields(param.firework.red, param.firework.green);
                    i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
                    break;
                default:
                    break;
            }
            
            prev_task = task; 
        }

        // 3. Handle Duration Expiration
        if (duration_ticks > 0) {
            elapsed_ticks++;
            if (elapsed_ticks >= duration_ticks) {
                // FALLBACK LOGIC: Read current configured idle state and transition to it
                led_task_t idle_t = (led_task_t)atomic_load_explicit(&s_led_idle_task, memory_order_relaxed);
                led_task_param_t idle_p;
                idle_p.raw = atomic_load_explicit(&s_led_idle_param, memory_order_relaxed);
                
                ledc_set_task(idle_t, idle_p, 0); // 0 duration sets it indefinitely
                supervisor_submit_event(EVENT_LED_EFFECT_COMPLETE);
                
                // NEW: Trigger the fade-in override, but skip it if the idle task is off or breathing
                if (idle_t != LED_IDLE && idle_t != LED_BREATHE) {
                    fade_ticks_remaining = FADE_IN_TICKS;
                }
                
                continue; // Skip the tick logic and re-evaluate state immediately
            }
        }

        // 4. Tick Animation Logic
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

            case LED_DEVICE_STATE: 
                // Checks to see if we need to flip the blink phase
                if (step_ctr % BLINK_INTERVAL_TICKS == 0) {
                    bool blink_on = (step_ctr / BLINK_INTERVAL_TICKS) % 2 == 0;
                    
                    uint16_t r_mask = param.device_state.red;
                    uint16_t g_mask = param.device_state.green;
                    
                    // If we're in the 'OFF' phase of a blink, mask out the blinking LEDs
                    if (!blink_on) {
                        r_mask &= ~(param.device_state.blink_mask);
                        g_mask &= ~(param.device_state.blink_mask);
                    }
                    
                    apply_led_bitfields(r_mask, g_mask);
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
            case LED_FIREWORK: {
                uint8_t current_ring = step_ctr / FIREWORK_TICKS_PER_RING;
                uint16_t r_mask = 0, g_mask = 0;
                
                uint8_t c_col = param.firework.center_bin / 2;
                uint8_t c_row = param.firework.center_bin % 2;

                uint8_t max_col_dist = (c_col > (6 - c_col)) ? c_col : (6 - c_col);
                uint8_t max_row_dist = (c_row > (1 - c_row)) ? c_row : (1 - c_row);
                uint8_t max_dist = max_col_dist + max_row_dist;

                int8_t target_dist = param.firework.implode ? (max_dist - current_ring) : current_ring;

                if (target_dist >= 0) {
                    for (int i = 0; i < 14; i++) {
                        uint8_t col = i / 2;
                        uint8_t row = i % 2;
                        uint8_t dist = abs(col - c_col) + abs(row - c_row);
                        
                        if (dist == target_dist) {
                            r_mask |= (1 << i);
                            g_mask |= (1 << i);
                        }
                    }
                }

                apply_led_bitfields(r_mask & param.firework.red, g_mask & param.firework.green);
                i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
                
                step_ctr++;
                break;
            }
            case LED_IDLE:
            default:
                break;
        }

        // 5. NEW: Process the Fade-in Override
        // This intercepts the end of the loop and enforces a lower brightness 
        // until the 500ms duration has fully elapsed.
        if (fade_ticks_remaining > 0) {
            uint32_t elapsed_fade = FADE_IN_TICKS - fade_ticks_remaining;
            uint8_t brightness = (MAX_BREATHE_STEPS * elapsed_fade) / FADE_IN_TICKS;
            
            IS31FL3730_set_brightness(brightness);
            i2c_write_register(ISSI_ADDR, ISSI_REG_UPDATE, 0x00);
            
            fade_ticks_remaining--;
        }

        vTaskDelay(pdMS_TO_TICKS(TASK_TICK_RATE_MS));
    }
}
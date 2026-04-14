/*
 * LED controller — emulator stub
 *
 * Replaces ledc.c when CONFIG_EMULATOR_MODE is set.  There is no LED hardware
 * in the emulator, so all effects are logged to the console.  Logging is
 * suppressed when nothing has changed (same task + params as before).
 *
 * Timed effects (duration_ms > 0) fire EVENT_LED_EFFECT_COMPLETE immediately
 * from a short-lived task so the supervisor state machine advances normally.
 */
#include "ledc.h"
#include "sdkconfig.h"

#if CONFIG_EMULATOR_MODE

#include <stdatomic.h>
#include <inttypes.h>
#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "supervisor.h"

#define TAG "LEDC"

static atomic_uint_fast32_t s_task        = ATOMIC_VAR_INIT(LED_IDLE);
static atomic_ullong        s_param       = ATOMIC_VAR_INIT(0);
static atomic_uint_fast32_t s_idle_task   = ATOMIC_VAR_INIT(LED_IDLE);
static atomic_ullong        s_idle_param  = ATOMIC_VAR_INIT(0);
static atomic_bool          s_timed_active = ATOMIC_VAR_INIT(false);

static void log_state(const char *prefix, led_task_t task, led_task_param_t p, uint32_t duration_ms)
{
    switch (task) {
        case LED_IDLE:
            ESP_LOGI(TAG, "%s: off", prefix);
            break;
        case LED_BREATHE:
            ESP_LOGI(TAG, "%s: breathe  r=0x%04x g=0x%04x  dur=%" PRIu32 "ms",
                     prefix, p.breathe.red, p.breathe.green, duration_ms);
            break;
        case LED_PROGRESS:
            ESP_LOGI(TAG, "%s: progress %d/7  r=0x%04x g=0x%04x  dur=%" PRIu32 "ms",
                     prefix, p.progress.progress, p.progress.red, p.progress.green, duration_ms);
            break;
        case LED_BLINK:
            ESP_LOGI(TAG, "%s: blink  r=0x%04x g=0x%04x  dur=%" PRIu32 "ms",
                     prefix, p.blink.red, p.blink.green, duration_ms);
            break;
        case LED_FIREWORK:
            ESP_LOGI(TAG, "%s: firework  center=%d implode=%d  r=0x%04x g=0x%04x  dur=%" PRIu32 "ms",
                     prefix, p.firework.center_bin, (int)p.firework.implode,
                     p.firework.red, p.firework.green, duration_ms);
            break;
        case LED_DEVICE_STATE:
            ESP_LOGI(TAG, "%s: device_state  r=0x%04x g=0x%04x blink=0x%04x  dur=%" PRIu32 "ms",
                     prefix, p.device_state.red, p.device_state.green,
                     p.device_state.blink_mask, duration_ms);
            break;
        default:
            ESP_LOGI(TAG, "%s: unknown task %d  dur=%" PRIu32 "ms", prefix, (int)task, duration_ms);
            break;
    }
}

static void effect_complete_task(void *arg)
{
    /* Yield for one tick so the calling context can finish queuing any
     * follow-up events (e.g. EVENT_REBOOT_REQUESTED) before this fires.
     * Without this, on a dual-core target the task can start on Core 1
     * and post EVENT_LED_EFFECT_COMPLETE before Core 0 has a chance to
     * post EVENT_REBOOT_REQUESTED, causing the supervisor to drop the
     * complete event while still in STATE_PROVISIONING. */
    vTaskDelay(1);
    atomic_store_explicit(&s_timed_active, false, memory_order_release);
    supervisor_submit_event(EVENT_LED_EFFECT_COMPLETE);
    vTaskDelete(NULL);
}

void ledc_init(void)
{
    ESP_LOGI(TAG, "LED controller initialized (emulator)");
}

void ledc_set_task(led_task_t task, led_task_param_t param, uint32_t duration_ms)
{
    led_task_t cur_task  = (led_task_t)atomic_load_explicit(&s_task,  memory_order_relaxed);
    uint64_t   cur_param =             atomic_load_explicit(&s_param, memory_order_relaxed);

    if (cur_task == task && cur_param == param.raw) {
        return;
    }

    atomic_store_explicit(&s_task,  task,      memory_order_relaxed);
    atomic_store_explicit(&s_param, param.raw, memory_order_relaxed);

    log_state("LED", task, param, duration_ms);

    if (duration_ms > 0) {
        atomic_store_explicit(&s_timed_active, true, memory_order_relaxed);
        xTaskCreate(effect_complete_task, "led_emu_cmp", 2048, NULL, 1, NULL);
    }
}

void ledc_set_idle_task(led_task_t task, led_task_param_t param)
{
    led_task_t cur_idle  = (led_task_t)atomic_load_explicit(&s_idle_task,  memory_order_relaxed);
    uint64_t   cur_param =             atomic_load_explicit(&s_idle_param, memory_order_relaxed);

    if (cur_idle == task && cur_param == param.raw) {
        return;
    }

    atomic_store_explicit(&s_idle_task,  task,      memory_order_relaxed);
    atomic_store_explicit(&s_idle_param, param.raw, memory_order_relaxed);

    log_state("LED (idle)", task, param, 0);

    if (!atomic_load_explicit(&s_timed_active, memory_order_acquire)) {
        ledc_set_task(task, param, 0);
    }
}

#endif /* CONFIG_EMULATOR_MODE */

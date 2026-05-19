#include "mux_io.h"
#include "ledc.h"
#include "sdkconfig.h"

#if CONFIG_EMULATOR_MODE

/* No MUX hardware in the emulator — provide empty stubs. */
void mux_init(void) { }
void mux_fresh_boot(void) { }
void mux_wake_deep_sleep(void) { }
bool mux_wake_deep_sleep_early(void) { return true; }
void mux_prep_deep_sleep(void) { }

#else /* !CONFIG_EMULATOR_MODE */

#include <string.h>
#include <stdatomic.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_sleep.h"
#include "esp_system.h"
#include "esp_task_wdt.h"
#include "esp_adc/adc_oneshot.h"
#include "esp_intr_alloc.h"
#include "esp_log.h"
#include "driver/rtc_io.h"
#include "driver/gpio.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/sens_reg.h"
#include "soc/periph_defs.h"

#include "ulp_adc.h"
#include "ulp.h"
#include "ulp_main.h"
#include "ulp/mux_config.h"
#include "mux_io.h"
#include "pill_pins.h"
#include "supervisor.h"
#include "battery.h"

#define TAG "MUX_IO"

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

extern uint32_t ulp_adc_readings_0;
extern uint32_t ulp_led_red_bits_0;
extern uint32_t ulp_led_green_bits_0;
extern uint32_t ulp_led_intensity_snap_0;
extern uint32_t ulp_primed;

static TaskHandle_t ulp_task_handle = NULL;
static atomic_bool s_raw_print = ATOMIC_VAR_INIT(false);

/* --- ADC channel layout --- */
#define ADC_READINGS                16
#define ADC_DOOR_CHANNEL_START      0
#define ADC_DOOR_CHANNEL_END        13
#define ADC_NUM_DOOR_CHANNELS       (ADC_DOOR_CHANNEL_END - ADC_DOOR_CHANNEL_START + 1)

/* --- LED leakage calibration thresholds --- */
#define LEAK_CAL_MIN_INTENSITY_SPAN 80
#define LEAK_CAL_LOW_INTENSITY_MAX  12
#define LEAK_CAL_HIGH_INTENSITY_MIN 100
#define LEAK_CAL_MIN_ADC_DELTA      60
#define LEAK_CAL_MIN_SAMPLES        24
#define LEAK_GLOBAL_MIN_SAMPLES     24
#define LEAK_GLOBAL_MIN_SPAN        80
#define LEAK_SLOPE_SHIFT            10

/* --- Common-mode cancellation --- */
#define CM_ADAPT_THRESHOLD          120
#define CM_OFFSET_ALPHA_SHIFT       3

/* --- Door detection thresholds --- */
#define DOOR_MAD_FLOOR              12
#define DOOR_MIN_EXCURSION          180
#define DOOR_OPEN_ABS_THRESHOLD     800
#define DOOR_CLOSE_ABS_THRESHOLD    400
#define DOOR_OPEN_Z_NUM             6
#define DOOR_AMBIENT_STEP_DELTA     120
#define DOOR_AMBIENT_STEP_CHANNELS  6
#define DOOR_OPEN_DEBOUNCE_SAMPLES  2
#define DOOR_CLOSE_DEBOUNCE_SAMPLES 3

/* --- EMA smoothing --- */
#define SCALE_FACTOR                256
#define ALPHA_SHIFT                 3

/* --- Wake reasons bitmask --- */
#define WAKE_REASON_NONE            0
#define WAKE_REASON_DOOR            (1 << 0)
#define WAKE_REASON_BATTERY         (1 << 1)

typedef enum {
    DOOR_CLOSED = 0,
    DOOR_OPEN = 1
} door_state_t;

static RTC_DATA_ATTR door_state_t rtc_last_known_state[ADC_NUM_DOOR_CHANNELS] = {DOOR_CLOSED};

/* Per-channel state tracking.  Must be RTC_DATA_ATTR to survive deep sleep. */
typedef struct {
    int32_t ema;
    int32_t mad;
    int32_t open_baseline;
    int32_t prev_adc;
    door_state_t state;
    uint8_t debounce_cnt;
    bool initialized;
    uint8_t reset_ctr;
} ch_stats_t;

static RTC_DATA_ATTR ch_stats_t ch_stats[ADC_NUM_DOOR_CHANNELS];
static RTC_DATA_ATTR uint32_t ulp_ctr = 0;
static uint32_t s_prev_bat_sample = 0;

typedef struct {
    uint8_t low_intensity;
    uint8_t high_intensity;
    int32_t low_adc;
    int32_t high_adc;
    uint16_t sample_count;
    int64_t sum_i;
    int64_t sum_a;
    int64_t sum_ii;
    int64_t sum_ia;
    int32_t slope_q10;   // raw ADC leakage slope in Q10
    int32_t intercept_q10;
    bool have_low;
    bool have_high;
    bool calibrated;
} leak_cal_t;

typedef struct {
    uint16_t sample_count;
    int64_t sum_i;
    int64_t sum_a;
    int64_t sum_ii;
    int64_t sum_ia;
    uint8_t low_intensity;
    uint8_t high_intensity;
    int32_t low_avg;
    int32_t high_avg;
    int32_t slope_q10;
    int32_t intercept_q10;
    bool calibrated;
} leak_global_cal_t;

static leak_cal_t s_leak_cal[ADC_NUM_DOOR_CHANNELS];
static leak_global_cal_t s_leak_global_cal;

typedef struct {
    int32_t offset_q8;
    bool initialized;
} cm_track_t;

static cm_track_t s_cm_track[ADC_NUM_DOOR_CHANNELS];

static RTC_DATA_ATTR uint16_t s_prev_led_state = 0;

static void init_ulp_program(void);
static void start_ulp_program(void);

static inline int32_t clamp_adc(int32_t v)
{
    if (v < 0) return 0;
    if (v > 4095) return 4095;
    return v;
}

static inline void sort_int32_asc(int32_t* a, int n)
{
    for (int i = 1; i < n; i++) {
        int32_t key = a[i];
        int j = i - 1;
        while (j >= 0 && a[j] > key) {
            a[j + 1] = a[j];
            j--;
        }
        a[j + 1] = key;
    }
}

typedef enum {
    CALIB_LED_OFF,
    CALIB_LED_OFF_SAMPLE,
    CALIB_LED_ON,
    CALIB_LED_ON_SAMPLE,
    CALIB_LED_50,
    CALIB_LED_50_SAMPLE,
    CALIB_NONE
} ulp_calib_state_t;

static ulp_calib_state_t s_calib_state = CALIB_LED_OFF;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warray-bounds"
static uint32_t RTC_IRAM_ATTR process_ulp_events(void)
{
    uint32_t wake_flags = WAKE_REASON_NONE;

    ulp_calib_state_t calib_state_before = s_calib_state;
    switch (s_calib_state) {
        case CALIB_LED_OFF:
            ledc_eng_unlock();
            ledc_set_idle_task(LED_SOLID, (led_task_param_t){
                .solid = {
                    .red = 0,
                    .green = 0,
                    .intensity = 0
                }
            });
            printf("LED OFF");
            ledc_eng_lock();
            if (ulp_ctr > 6)
                s_calib_state = CALIB_LED_OFF_SAMPLE;
            break;
        case CALIB_LED_OFF_SAMPLE:
            s_calib_state = CALIB_LED_ON;
            break;
        case CALIB_LED_ON:
            ledc_eng_unlock();
            ledc_set_idle_task(LED_SOLID, (led_task_param_t){
                .solid = {
                    .red = LED_ALL_DOORS,
                    .green = LED_ALL_DOORS,
                    .intensity = 127
                }
            });
            printf("LED ON");
            ledc_eng_lock();
            if (ulp_ctr > 12) {
                s_calib_state = CALIB_LED_ON_SAMPLE;
            }
            break;
        case CALIB_LED_ON_SAMPLE:
            s_calib_state = CALIB_LED_50;
            break;
        case CALIB_LED_50:
            ledc_eng_unlock();
            ledc_set_idle_task(LED_SOLID, (led_task_param_t){
                .solid = {
                    .red = LED_ALL_DOORS,
                    .green = LED_ALL_DOORS,
                    .intensity = 64
                }
            });
            printf("LED 50");
            ledc_eng_lock();
            if (ulp_ctr > 18) {
                s_calib_state = CALIB_LED_50_SAMPLE;
            }
            break;
        case CALIB_LED_50_SAMPLE:
            s_calib_state = CALIB_NONE;
            ledc_eng_unlock();
            break;
        case CALIB_NONE:
            break;
    }

    uint32_t* values      = &ulp_adc_readings_0;
    uint32_t red_bits     = ulp_led_red_bits_0 & 0xFFFF;
    uint32_t green_bits   = ulp_led_green_bits_0 & 0xFFFF;
    uint32_t* intensities = &ulp_led_intensity_snap_0;

    /* --- Battery presence & square-wave filtering --- */
    uint32_t bat_start_val = s_prev_bat_sample & 0xFFFF;
    uint32_t bat_end_val   = values[14] & 0xFFFF;
    uint32_t vbus_val      = values[15] & 0xFFFF;
    s_prev_bat_sample      = bat_end_val;

    /* First ULP iteration — skip to allow the battery sample swap. */
    if (ulp_ctr++ == 0) {
        return wake_flags;
    }

    if (battery_submit_adc_readings(bat_start_val, bat_end_val, vbus_val)) {
        wake_flags |= WAKE_REASON_BATTERY;
    }

    /* Discard readings during charger pulse to protect door baselines. */
    if (battery_get_presence() == BATTERY_PRESENCE_DISCONNECTED &&
        battery_is_pulse_high(bat_start_val, bat_end_val)) {
        return wake_flags;
    }

    int32_t raw_adc[ADC_READINGS] = {0};
    int32_t corrected_adc[ADC_READINGS] = {0};
    uint8_t red_on[ADC_READINGS] = {0};
    uint8_t intensity[ADC_READINGS] = {0};

    for (int i = 0; i < ADC_READINGS; i++) {
        raw_adc[i] = (int32_t)(values[i] & 0xFFFF);
        corrected_adc[i] = raw_adc[i];
        red_on[i] = (uint8_t)((red_bits >> i) & 0x1);
        intensity[i] = (uint8_t)(intensities[i] & 0xFF);
    }

    int32_t avg_adc_raw = 0;
    int32_t avg_intensity = 0;
    int red_count = 0;
    for (int i = ADC_DOOR_CHANNEL_START; i <= ADC_DOOR_CHANNEL_END; i++) {
        if (red_on[i]) {
            avg_adc_raw += raw_adc[i];
            avg_intensity += intensity[i];
            red_count++;
        }
    }
    if (red_count > 0) {
        avg_adc_raw /= red_count;
        avg_intensity /= red_count;
    }

    bool is_calib_sample = (calib_state_before == CALIB_LED_OFF_SAMPLE ||
                            calib_state_before == CALIB_LED_ON_SAMPLE ||
                            calib_state_before == CALIB_LED_50_SAMPLE);

    if ((red_count > 0 || is_calib_sample) && !s_leak_global_cal.calibrated) {
        leak_global_cal_t* g = &s_leak_global_cal;
        if (red_count > 0) {
            if (g->sample_count < UINT16_MAX) g->sample_count++;
            g->sum_i += avg_intensity;
            g->sum_a += avg_adc_raw;
            g->sum_ii += (int64_t)avg_intensity * (int64_t)avg_intensity;
            g->sum_ia += (int64_t)avg_intensity * (int64_t)avg_adc_raw;
        }

        if (calib_state_before == CALIB_LED_OFF_SAMPLE) {
            g->low_intensity = 0;
            g->low_avg = avg_adc_raw;
        }
        if (calib_state_before == CALIB_LED_ON_SAMPLE) {
            g->high_intensity = (uint8_t)avg_intensity;
            g->high_avg = avg_adc_raw;
        }

        if (g->sample_count >= LEAK_GLOBAL_MIN_SAMPLES &&
            g->high_intensity > g->low_intensity &&
            (g->high_intensity - g->low_intensity) >= LEAK_GLOBAL_MIN_SPAN &&
            (g->high_avg - g->low_avg) >= LEAK_CAL_MIN_ADC_DELTA) {
            int64_t n = g->sample_count;
            int64_t denom = (n * g->sum_ii) - (g->sum_i * g->sum_i);
            if (denom > 0) {
                int64_t numer = (n * g->sum_ia) - (g->sum_i * g->sum_a);
                int64_t slope_q10 = (numer << LEAK_SLOPE_SHIFT) / denom;
                if (slope_q10 < 0) slope_q10 = 0;
                g->slope_q10 = (int32_t)slope_q10;
                g->intercept_q10 = (int32_t)(((g->sum_a << LEAK_SLOPE_SHIFT) - (slope_q10 * g->sum_i)) / n);
                g->calibrated = true;
            }
        }
    }

    int32_t global_residual = 0;
    if (red_count > 0 && s_leak_global_cal.calibrated) {
        int32_t global_pred = (int32_t)((((int64_t)s_leak_global_cal.slope_q10 * (int64_t)avg_intensity) + s_leak_global_cal.intercept_q10) >> LEAK_SLOPE_SHIFT);
        global_residual = avg_adc_raw - global_pred;
        if (global_residual < 0) global_residual = 0;
    }

    for (int i = ADC_DOOR_CHANNEL_START; i <= ADC_DOOR_CHANNEL_END; i++) {
        if (!red_on[i] && !is_calib_sample) {
            continue;
        }

        leak_cal_t* c = &s_leak_cal[i];
        int32_t adc = raw_adc[i];
        uint8_t cur_intensity = intensity[i];

        if (!c->calibrated) {
            if (red_on[i]) {
                if (c->sample_count < UINT16_MAX) c->sample_count++;
                c->sum_i += cur_intensity;
                c->sum_a += adc;
                c->sum_ii += (int64_t)cur_intensity * (int64_t)cur_intensity;
                c->sum_ia += (int64_t)cur_intensity * (int64_t)adc;
            }

            if (calib_state_before == CALIB_LED_OFF_SAMPLE) {
                c->low_intensity = 0;
                c->low_adc = adc;
                c->have_low = true;
            }
            if (calib_state_before == CALIB_LED_ON_SAMPLE) {
                c->high_intensity = cur_intensity;
                c->high_adc = adc;
                c->have_high = true;
            }
        }

        if (!c->calibrated &&
            c->have_low &&
            c->have_high &&
            c->high_intensity > c->low_intensity &&
            (c->high_intensity - c->low_intensity) >= LEAK_CAL_MIN_INTENSITY_SPAN &&
            c->low_intensity <= LEAK_CAL_LOW_INTENSITY_MAX &&
            c->high_intensity >= LEAK_CAL_HIGH_INTENSITY_MIN &&
            (c->high_adc - c->low_adc) >= LEAK_CAL_MIN_ADC_DELTA &&
            c->sample_count >= LEAK_CAL_MIN_SAMPLES) {
            int64_t n = c->sample_count;
            int64_t denom = (n * c->sum_ii) - (c->sum_i * c->sum_i);
            if (denom > 0) {
                int64_t numer = (n * c->sum_ia) - (c->sum_i * c->sum_a);
                int64_t slope_q10 = (numer << LEAK_SLOPE_SHIFT) / denom;
                if (slope_q10 < 0) slope_q10 = 0;
                c->slope_q10 = (int32_t)slope_q10;
                c->intercept_q10 = (int32_t)(((c->sum_a << LEAK_SLOPE_SHIFT) - (slope_q10 * c->sum_i)) / n);
                c->calibrated = true;
            }
        }

        if (c->calibrated) {
            int32_t leakage = (int32_t)((((int64_t)c->slope_q10 * (int64_t)cur_intensity) + c->intercept_q10) >> LEAK_SLOPE_SHIFT);
            corrected_adc[i] = clamp_adc(adc - leakage - global_residual);
        }
    }

    /* --- Common-mode cancellation --- */
    int32_t cm_vals[ADC_NUM_DOOR_CHANNELS];
    for (int i = 0; i < ADC_NUM_DOOR_CHANNELS; i++) {
        cm_vals[i] = corrected_adc[i];
    }
    sort_int32_asc(cm_vals, ADC_NUM_DOOR_CHANNELS);

    /* Trim two lowest and two highest bins to avoid door/outlier influence. */
    int32_t cm_sum = 0;
    for (int i = 2; i < (ADC_NUM_DOOR_CHANNELS - 2); i++) {
        cm_sum += cm_vals[i];
    }
    int32_t cm_common = cm_sum / (ADC_NUM_DOOR_CHANNELS - 4);

    int ambient_step_count = 0;
    for (int i = ADC_DOOR_CHANNEL_START; i <= ADC_DOOR_CHANNEL_END; i++) {
        cm_track_t* t = &s_cm_track[i];

        if (!t->initialized) {
            t->offset_q8 = (corrected_adc[i] - cm_common) << 8;
            t->initialized = true;
        }

        int32_t pred = cm_common + (t->offset_q8 >> 8);
        int32_t resid = corrected_adc[i] - pred;

        if (resid < CM_ADAPT_THRESHOLD && resid > -CM_ADAPT_THRESHOLD) {
            t->offset_q8 += ((resid << 8) >> CM_OFFSET_ALPHA_SHIFT);
        }

        if (ch_stats[i].initialized && (resid - ch_stats[i].prev_adc) > DOOR_AMBIENT_STEP_DELTA) {
            ambient_step_count++;
        }

        /* We care about positive excursions (door opens) after common-mode removal. */
        corrected_adc[i] = clamp_adc(resid);
    }

    if (atomic_load_explicit(&s_raw_print, memory_order_relaxed)) {
        printf("MUX raw:");
        for (int i = 0; i < 14; i++) {
            printf("\t%lu\t%lu", (uint32_t)corrected_adc[i], (uint32_t)raw_adc[i]);
        }
        printf("\t%lu\t%lu\n", avg_adc_raw, avg_intensity);
    }

    /* --- Door open/close detection with debounce --- */
    if (s_calib_state == CALIB_NONE) {
        for (int i = ADC_DOOR_CHANNEL_START; i <= ADC_DOOR_CHANNEL_END; i++) {
            ch_stats_t* ch = &ch_stats[i];
            int32_t adc = corrected_adc[i];

            if (ch->state == DOOR_CLOSED) {
                if (adc > DOOR_OPEN_ABS_THRESHOLD) {
                    ch->debounce_cnt++;
                    if (ch->debounce_cnt >= DOOR_OPEN_DEBOUNCE_SAMPLES) {
                        ch->state = DOOR_OPEN;
                        ch->debounce_cnt = 0;
                        wake_flags |= WAKE_REASON_DOOR;
                    }
                } else {
                    ch->debounce_cnt = 0;
                }
            } else { /* DOOR_OPEN */
                if (adc < DOOR_CLOSE_ABS_THRESHOLD) {
                    ch->debounce_cnt++;
                    if (ch->debounce_cnt >= DOOR_CLOSE_DEBOUNCE_SAMPLES) {
                        ch->state = DOOR_CLOSED;
                        ch->debounce_cnt = 0;
                        wake_flags |= WAKE_REASON_DOOR;
                    }
                } else {
                    ch->debounce_cnt = 0;
                }
            }
        }
    }

    return wake_flags;
}
#pragma GCC diagnostic pop

static void IRAM_ATTR ulp_isr_handler(void *arg)
{
    BaseType_t woken = pdFALSE;
    vTaskNotifyGiveFromISR(ulp_task_handle, &woken);
    if (woken) portYIELD_FROM_ISR();
}

static void ulp_event_task(void *arg)
{
    ESP_ERROR_CHECK(esp_task_wdt_add(NULL));

    while (1) {
        uint32_t notified = ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(10000));
        if (notified == 0) {
            ESP_LOGE(TAG, "ULP software watchdog timeout! Resetting...");
            esp_restart();
        }

        esp_task_wdt_reset();

        uint32_t wake_reasons = process_ulp_events();

        if (wake_reasons & WAKE_REASON_BATTERY) {
            ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_BATTERY_CHANGE, 0, pdMS_TO_TICKS(100)));
        }

        for (int i = 0; i < ADC_NUM_DOOR_CHANNELS; i++) {
            if (ch_stats[i].state == rtc_last_known_state[i]) continue;

            ESP_LOGI(TAG, "Door %d | STATE: %s | Real ADC: %ld | MAD: %ld",
                     i,
                     ch_stats[i].state == DOOR_OPEN ? "OPEN" : "CLOSED",
                     ch_stats[i].ema / SCALE_FACTOR,
                     ch_stats[i].mad / SCALE_FACTOR);

            esp_err_t err;
            if (ch_stats[i].state == DOOR_OPEN) {
                err = supervisor_submit_event_block(EVENT_DOOR_OPENED, (intptr_t)i, pdMS_TO_TICKS(10));
            } else {
                err = supervisor_submit_event_block(EVENT_DOOR_CLOSED, (intptr_t)i, pdMS_TO_TICKS(10));
            }

            if (err == ESP_OK) {
                rtc_last_known_state[i] = ch_stats[i].state;
            }
        }
    }
}


void mux_init(void)
{
    xTaskCreatePinnedToCore(ulp_event_task, "ulp_event_task", 4096, NULL, 5, &ulp_task_handle, 0);
    ESP_ERROR_CHECK(ulp_isr_register(ulp_isr_handler, NULL));
    REG_SET_BIT(RTC_CNTL_INT_ENA_REG, RTC_CNTL_ULP_CP_INT_ENA);
    ESP_LOGI(TAG, "MUX driver initialized");
}

void mux_prep_deep_sleep(void)
{
    REG_CLR_BIT(RTC_CNTL_INT_ENA_REG, RTC_CNTL_ULP_CP_INT_ENA);
    ESP_ERROR_CHECK(esp_sleep_enable_ulp_wakeup());
}

void mux_fresh_boot(void)
{
    /* Stop first — the ULP FSM may still be running after a warm reset. */
    ulp_timer_stop();
    vTaskDelay(pdMS_TO_TICKS(200));

    init_ulp_program();
    start_ulp_program();
}

void mux_wake_deep_sleep(void)
{
}

bool RTC_IRAM_ATTR mux_wake_deep_sleep_early(void)
{
    return process_ulp_events() != WAKE_REASON_NONE;
}

static void init_ulp_program(void)
{
    memset((void *)ch_stats, 0, sizeof(ch_stats));
    memset((void *)rtc_last_known_state, 0, sizeof(rtc_last_known_state));
    memset((void *)s_leak_cal, 0, sizeof(s_leak_cal));
    memset((void *)&s_leak_global_cal, 0, sizeof(s_leak_global_cal));
    memset((void *)s_cm_track, 0, sizeof(s_cm_track));
    s_prev_bat_sample = 0;

    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    ulp_adc_cfg_t cfg = {
        .adc_n    = (adc_unit_t)MUX_ADC_UNIT,
        .channel  = (adc_channel_t)MUX_ADC_CHANNEL,
        .atten    = (adc_atten_t)MUX_ADC_ATTEN,
        .width    = (adc_bitwidth_t)MUX_ADC_WIDTH,
        .ulp_mode = ADC_ULP_MODE_FSM,
    };
    ESP_ERROR_CHECK(ulp_adc_init(&cfg));

    /* RTC GPIOs for MUX select lines */
    const gpio_num_t mux_pins[] = {MUX_PIN_A, MUX_PIN_B, MUX_PIN_C, MUX_PIN_D};
    for (int i = 0; i < 4; i++) {
        rtc_gpio_init(mux_pins[i]);
        rtc_gpio_set_direction(mux_pins[i], RTC_GPIO_MODE_OUTPUT_ONLY);
    }

    /* 10ms ULP wakeup period — 16 ticks per full cycle (~160ms) */
    ulp_set_wakeup_period(0, 10000);

#if CONFIG_IDF_TARGET_ESP32 && !defined(CONFIG_FIRMWARE_ENGINEERING)
    /* Isolate JTAG/bootstrap pins to save deep-sleep power. */
    rtc_gpio_isolate(GPIO_NUM_12);
    rtc_gpio_isolate(GPIO_NUM_15);
#endif

    esp_deep_sleep_disable_rom_logging();
}

static void start_ulp_program(void)
{
    ESP_ERROR_CHECK(ulp_run(&ulp_entry - RTC_SLOW_MEM));
}

void mux_force_door_state_reset(int door_id)
{
    if (door_id >= 0 && door_id < ADC_NUM_DOOR_CHANNELS) {
        ch_stats[door_id].initialized = false;
        ESP_LOGI(TAG, "Forced state reset for door %d", door_id);
    }
}

bool mux_eng_toggle_raw_print(void)
{
    bool prev = atomic_load_explicit(&s_raw_print, memory_order_relaxed);
    atomic_store_explicit(&s_raw_print, !prev, memory_order_relaxed);
    return !prev;
}

#endif /* !CONFIG_EMULATOR_MODE */

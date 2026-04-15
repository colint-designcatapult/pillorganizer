#include "sleep_state.h"
#include "sdkconfig.h"
#include <time.h>

RTC_DATA_ATTR time_t   s_sleep_entry_unix_sec    = 0;
RTC_DATA_ATTR uint64_t s_sleep_entry_rtc_ticks   = 0;
RTC_DATA_ATTR uint32_t s_sleep_rtc_ticks_per_sec = 150000; /* safe default ~150 kHz */

#if !CONFIG_EMULATOR_MODE

#include "soc/rtc_cntl_reg.h"
#include "esp_private/esp_clk.h"

static uint64_t read_rtc_ticks(void)
{
    /* Latch the current RTC timer value into the shadow registers */
    REG_SET_BIT(RTC_CNTL_TIME_UPDATE_REG, RTC_CNTL_TIME_UPDATE);
    while (!REG_GET_BIT(RTC_CNTL_TIME_UPDATE_REG, RTC_CNTL_TIME_VALID)) {}
    return ((uint64_t)REG_READ(RTC_CNTL_TIME1_REG) << 32) | REG_READ(RTC_CNTL_TIME0_REG);
}

void sleep_store_time_base(void)
{
    s_sleep_entry_unix_sec  = time(NULL);
    s_sleep_entry_rtc_ticks = read_rtc_ticks();

    /* esp_clk_slowclk_cal_get() returns the slow-clock period in microseconds
     * as a Q19 fixed-point value: period_us = cal / 2^19.
     * Rearranged: ticks_per_sec = 1_000_000 * 2^19 / cal */
    uint32_t cal = esp_clk_slowclk_cal_get();
    if (cal > 0) {
        s_sleep_rtc_ticks_per_sec = (uint32_t)(1000000ULL * (1ULL << 19) / cal);
    }
}

#else /* CONFIG_EMULATOR_MODE */

void sleep_store_time_base(void) { /* no-op: no deep sleep in emulator */ }

#endif /* CONFIG_EMULATOR_MODE */

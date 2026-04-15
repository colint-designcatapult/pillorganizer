#pragma once
#include <time.h>
#include <stdint.h>
#include "esp_attr.h"

/* RTC-retained time base for wake stub computations.
 * Written by sleep_store_time_base() immediately before deep sleep entry.
 * Read by wake_stub_check_pending_bins() in main.c (RTC_IRAM_ATTR context). */
extern RTC_DATA_ATTR time_t   s_sleep_entry_unix_sec;
extern RTC_DATA_ATTR uint64_t s_sleep_entry_rtc_ticks;
extern RTC_DATA_ATTR uint32_t s_sleep_rtc_ticks_per_sec;

/* Store the current Unix time and RTC tick base into RTC memory.
 * Must be called immediately before mux_prep_deep_sleep() / esp_deep_sleep_start(). */
void sleep_store_time_base(void);

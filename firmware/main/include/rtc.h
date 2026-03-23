#pragma once
#include <stdint.h>
#include <time.h>

void app_rtc_init();
void app_rtc_sync();

typedef uint64_t rtc_relative_time_t;

// Gets a timestamp that can be converted to UTC time regardless of RTC sync status
rtc_relative_time_t app_rtc_get_relative_timestamp();

// Converts a relative timestamp to UTC time, given that the RTC has been synced
time_t app_rtc_calc_utc_time_ms(rtc_relative_time_t rtc_time);

int64_t app_rtc_calc_duration_ms(rtc_relative_time_t start, rtc_relative_time_t end);
#pragma once
#include <stdint.h>
#include <time.h>
#include <esp_err.h>
#include <stdbool.h>

void app_rtc_init();
void app_rtc_sync();

typedef uint64_t rtc_relative_time_t;
typedef int64_t rtc_utc_timestamp_ms;

// Gets a timestamp that can be converted to UTC time regardless of RTC sync status
rtc_relative_time_t app_rtc_get_relative_timestamp();

esp_err_t app_rtc_get_utc_timestamp_ms(rtc_utc_timestamp_ms* ts);

// Converts a relative timestamp to UTC time, given that the RTC has been synced
time_t app_rtc_calc_utc_time_ms(rtc_relative_time_t rtc_time);

int64_t app_rtc_calc_duration_ms(rtc_relative_time_t start, rtc_relative_time_t end);

esp_err_t app_rtc_get_current_epoch_week(time_t* epoch_week);

bool app_rtc_time_synced();

// Sets the system timezone using a POSIX TZ string (e.g. "EST5EDT,M3.2.0,M11.1.0").
// Calls setenv("TZ", ...) and tzset().
void app_rtc_set_timezone(const char* posix_tz);
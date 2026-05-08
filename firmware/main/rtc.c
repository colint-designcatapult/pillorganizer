#include "rtc.h"
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>
#include "esp_log.h"
#include "esp_netif_sntp.h"
#include "esp_sntp.h"
#include "supervisor.h"
#include <esp_timer.h>
#include <esp32/rtc.h>
#include "assert.h"

#define TAG "RTC"

#define SYNC_STALE_THRESHOLD_US (24ULL * 60ULL * 60ULL * 1000000ULL)

RTC_DATA_ATTR static time_t last_sntp_sync_time = 0;
RTC_DATA_ATTR static uint64_t last_sync_rtc_time = 0;

void app_rtc_set_timezone(const char* posix_tz)
{
    if (posix_tz && posix_tz[0] != '\0') {
        setenv("TZ", posix_tz, 1);
        tzset();
        ESP_LOGI(TAG, "Timezone set to: %s", posix_tz);
    }
}

void app_rtc_time_sync_notification_cb(struct timeval *tv)
{
    ESP_LOGI(TAG, "Asynchronous SNTP sync complete!");

    // Log the updated time
    time_t now = 0;
    struct tm timeinfo = { 0 };
    time(&now);
    localtime_r(&now, &timeinfo);
    
    char strftime_buf[64];
    strftime(strftime_buf, sizeof(strftime_buf), "%c", &timeinfo);
    ESP_LOGI(TAG, "Current time updated to: %s", strftime_buf);

    // Set last sync time to RTC memory
    last_sntp_sync_time = now;
    last_sync_rtc_time = esp_rtc_get_time_us();

    // Notify system of time sync
    ESP_ERROR_CHECK(supervisor_submit_event(EVENT_TIME_SYNCED));
}

void app_rtc_init()
{
    ESP_LOGI(TAG, "Initializing and starting SNTP");

    // Configure the SNTP service to use our callback
    esp_sntp_config_t config = ESP_NETIF_SNTP_DEFAULT_CONFIG("pool.ntp.org");
    config.sync_cb = app_rtc_time_sync_notification_cb;
    
    // Initialize the SNTP service
    esp_netif_sntp_init(&config);

    ESP_LOGI(TAG, "RTC/SNTP initialized");
}

void app_rtc_sync()
{
    ESP_LOGI(TAG, "Forcing sync with SNTP");
    sntp_restart();
}

rtc_relative_time_t app_rtc_get_relative_timestamp()
{
    return esp_rtc_get_time_us();
}

esp_err_t app_rtc_get_utc_timestamp_ms(rtc_utc_timestamp_ms* timestamp)
{
    if (last_sntp_sync_time == 0) {
        // We don't have a valid time yet
        return ESP_ERR_INVALID_STATE;
    }
    if (esp_rtc_get_time_us() - last_sync_rtc_time > SYNC_STALE_THRESHOLD_US) {
        ESP_LOGW(TAG, "Last SNTP sync was over 24 hours ago");
        return ESP_ERR_INVALID_STATE;
    }
    struct timeval tv;

    gettimeofday(&tv, NULL);
    // Convert seconds and microseconds to milliseconds
    *timestamp = (int64_t)tv.tv_sec * 1000LL + (int64_t)tv.tv_usec / 1000LL;
    return ESP_OK;
}

time_t app_rtc_calc_utc_time_ms(rtc_relative_time_t rtc_time)
{
    // Time must be synced to use this function
    assert(last_sync_rtc_time != 0);

    // 1. Cast both to int64_t before subtracting so we don't underflow.
    // 2. Do (event - sync) so positive means "after sync" and negative means "before sync".
    int64_t time_diff_us = (int64_t)rtc_time - (int64_t)last_sync_rtc_time;
    
    // Convert the difference to seconds and ADD to the synced UTC time.
    // CRITICAL: Use 1000000LL (signed) instead of ULL so the division handles negative differences correctly.
    time_t event_utc_time = last_sntp_sync_time + (time_t)(time_diff_us / 1000LL);
    
    return event_utc_time;
}

int64_t app_rtc_calc_duration_ms(rtc_relative_time_t start, rtc_relative_time_t end)
{
    int64_t diff = (int64_t)end - (int64_t)start;
    return diff / 1000LL;
}

esp_err_t app_rtc_get_current_epoch_week(time_t* epoch_week)
{
    if (last_sntp_sync_time == 0) {
        // We don't have a valid time yet
        return ESP_ERR_INVALID_STATE;
    }

    // 1. Get the current absolute time
    time_t current_sec = time(NULL);
    if (current_sec == (time_t)-1) {
        return ESP_ERR_INVALID_STATE;
    }

    // 2. Convert to local time to inspect the days
    struct tm current_local_tm;
    localtime_r(&current_sec, &current_local_tm);

    // 3. Figure out how many days we are past Monday
    // Standard tm_wday: 0=Sun, 1=Mon... 6=Sat
    // Mapped to days_since_monday: 0=Mon, 1=Tue... 6=Sun
    int days_since_monday = (current_local_tm.tm_wday + 6) % 7;

    // 4. Roll the date back to Monday
    current_local_tm.tm_mday -= days_since_monday; // mktime safely handles negative days if rolling over a month boundary
    
    // 5. Zero out the time to exactly Midnight (00:00:00)
    current_local_tm.tm_hour = 0;
    current_local_tm.tm_min  = 0;
    current_local_tm.tm_sec  = 0;

    // 6. Tell mktime to figure out if DST was active on that specific Monday
    current_local_tm.tm_isdst = -1;

    // 7. Convert back to an absolute time_t timestamp
    *epoch_week = mktime(&current_local_tm);

    return ESP_OK;
}

bool app_rtc_time_synced()
{
    if (last_sntp_sync_time == 0) return false;
    return (esp_rtc_get_time_us() - last_sync_rtc_time) <= SYNC_STALE_THRESHOLD_US;
}
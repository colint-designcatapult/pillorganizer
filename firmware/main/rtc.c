#include "rtc.h"
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

RTC_DATA_ATTR static time_t last_sntp_sync_time = 0;
RTC_DATA_ATTR static uint64_t last_sync_rtc_time = 0;

void app_rtc_time_sync_notification_cb(struct timeval *tv)
{
    ESP_LOGI(TAG, "Asynchronous SNTP sync complete!");
    
    // You can set your timezone here now that the system time is valid
    setenv("TZ", "EST5EDT,M3.2.0/2,M11.1.0", 1);
    tzset();

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

time_t app_rtc_calc_utc_time(rtc_relative_time_t rtc_time)
{
    // Time must be synced to use this function
    assert(last_sync_rtc_time != 0);

    // Calculate how many microseconds before the sync the event occurred
    int64_t time_diff_us = last_sync_rtc_time - rtc_time;
    
    // Convert the difference to seconds and subtract from the synced UTC time
    time_t event_utc_time = last_sntp_sync_time - (time_t)(time_diff_us / 1000000ULL);
    
    return event_utc_time;
}
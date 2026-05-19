#include "supervisor_ota.h"
#include "supervisor.h"
#include "ota.h"
#include "network.h"
#include "rtc.h"
#include "ledc.h"
#include <esp_log.h>

#define TAG "SUPERVISOR_OTA"

typedef enum {
    STATE_CONNECTING_NETIF,
    STATE_SYNCING_TIME,
    STATE_DOWNLOADING,
    STATE_REBOOTING,
} supervisor_ota_state_t;

static supervisor_ota_state_t s_state;
static ota_job_t s_job;

static void handle_download_failure(void)
{
    /* Empty version string forces a FAILED report in operational mode via
     * ota_init() + ota_on_connect() on the next boot. */
    ota_store_boot_validation(s_job.job_id, "");
    ledc_set_task(LED_BLINK, (led_task_param_t){
        .blink = { .red = LED_ALL_DOORS, .green = 0x00 }
    }, 2000);
    s_state = STATE_REBOOTING;
    supervisor_submit_event(EVENT_REBOOT_REQUESTED);
}

bool supervisor_ota_init(void)
{
    esp_err_t err = ota_load_and_clear_pending_job(&s_job);
    if (err != ESP_OK) {
        return false;
    }

    ESP_LOGI(TAG, "Pending OTA job found: id=%s version=%s — entering OTA mode",
             s_job.job_id, s_job.version);

    /* All LEDs solid red to indicate OTA mode is active */
    ledc_set_idle_task(LED_SOLID, (led_task_param_t){
        .solid = { .red = LED_ALL_DOORS, .green = 0x00, .intensity = 128 }
    });

    s_state = STATE_CONNECTING_NETIF;
    return true;
}

void supervisor_ota_event(const supervisor_event_t* event)
{
    switch (s_state) {
        case STATE_CONNECTING_NETIF:
            if (event->id == EVENT_NETIF_CONNECTED) {
                s_state = STATE_SYNCING_TIME;
                app_rtc_sync();
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                ESP_LOGW(TAG, "Network disconnected, retrying...");
                network_reconnect();
            }
            break;

        case STATE_SYNCING_TIME:
            if (event->id == EVENT_TIME_SYNCED) {
                ESP_LOGI(TAG, "Time synced — starting OTA download");
                esp_err_t err = ota_execute_job(&s_job);
                if (err != ESP_OK) {
                    ESP_LOGE(TAG, "Failed to start OTA worker (%d) — treating as failure", err);
                    handle_download_failure();
                } else {
                    s_state = STATE_DOWNLOADING;
                }
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                s_state = STATE_CONNECTING_NETIF;
                network_reconnect();
            }
            break;

        case STATE_DOWNLOADING:
            if (event->id == EVENT_OTA_COMPLETE) {
                ESP_LOGI(TAG, "OTA flash succeeded — storing boot-validation, rebooting");
                /* Store the target version so operational mode reports SUCCEEDED
                 * via ota_on_connect() after the new firmware boots. */
                ota_store_boot_validation(s_job.job_id, s_job.version);
                ledc_set_task(LED_BREATHE, (led_task_param_t){
                    .breathe = { .red = 0x00, .green = LED_ALL_DOORS }
                }, 2000);
                s_state = STATE_REBOOTING;
                supervisor_submit_event(EVENT_REBOOT_REQUESTED);
            } else if (event->id == EVENT_OTA_FAILED) {
                ESP_LOGE(TAG, "OTA download failed — storing failure, rebooting");
                handle_download_failure();
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                /* The worker task runs HTTPS independently — it will fail and post
                 * EVENT_OTA_FAILED if the connection is lost mid-download. */
                ESP_LOGW(TAG, "Network disconnected during OTA download");
            }
            break;

        default:
            break;
    }
}

void supervisor_ota_tick(void)
{
    /* All transitions are event-driven; nothing to do on tick. */
}


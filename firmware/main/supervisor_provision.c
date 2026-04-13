#include "supervisor_provision.h"
#include "device_config.h"
#include <esp_log.h>
#include "network.h"
#include "claim.h"
#include "sdkconfig.h"

#if !CONFIG_EMULATOR_MODE
#include "wifi_provision.h"
#include "ledc.h"
#endif

#define TAG "SUPERVISOR_PROVISION"

typedef enum {
    STATE_INIT,
    STATE_WIFI_PROVISIONING,
    STATE_CONNECTING_NETIF,
    STATE_SYNCING_TIME,
    STATE_FETCHING_CERT,
    STATE_FLEET_PROVISIONING,
    STATE_FAILED
} supervisor_provision_state_t;

static supervisor_provision_state_t s_state = STATE_INIT;

// Number of provision failures this boot
static uint8_t s_provision_fail_ctr = 0;

static void provisioning_failed()
{
    s_state = STATE_FAILED;
#if !CONFIG_EMULATOR_MODE
    wifiprov_reset_provision();
#endif
    devcfg_reset_identity();

#if !CONFIG_EMULATOR_MODE
    // Blink red to indicate failure
    led_task_param_t param = {
        .blink = {
            .red = LED_ALL_DOORS,
            .green = 0x00
        }
    };
    ledc_set_task(LED_BLINK, param, 3000);
#else
    ESP_LOGW(TAG, "Provisioning failed (emulator mode)");
#endif

    ESP_ERROR_CHECK(supervisor_submit_event(EVENT_REBOOT_REQUESTED));
}

bool supervisor_provision_init()
{
#if CONFIG_EMULATOR_MODE
    /* In emulator mode there is no BLE/Wi-Fi provisioning.
     * If the device already has a permanent identity, go straight to operational.
     * Otherwise, wait for Ethernet to come up (EVENT_NETIF_CONNECTED in STATE_INIT)
     * then sync time, then wait for the engineering CLI to supply claim credentials. */
    if (devcfg_has_permanent_identity()) {
        return false; /* fully provisioned → operational */
    }
    ESP_LOGI(TAG, "Emulator: awaiting provisioning via engineering CLI");
    s_state = STATE_INIT;
    return true;
#else
    if (wifiprov_is_provisioned()) {
        // Device provisioned with Wi-Fi Credentials, network stack is already connecting
        if(devcfg_has_permanent_identity()) {
            // Permanent identity assigned. Fully provisioned.
            return false;
        } else {
            provisioning_failed();
        }
    } else {
        wifiprov_start_provision();
    }
    return true;
#endif
}

void supervisor_provision_event(const supervisor_event_t* event)
{
    switch (s_state) {
        case STATE_INIT:
#if CONFIG_EMULATOR_MODE
            /* In emulator mode, jump to time-sync once the network is up.
             * The CLI delivers credentials via EVENT_CLAIM_CREDENTIALS_RECEIVED
             * which is handled in STATE_SYNCING_TIME below. */
            if (event->id == EVENT_NETIF_CONNECTED) {
                s_state = STATE_SYNCING_TIME;
                app_rtc_sync();
            }
#else
            if (event->id == EVENT_PROVISION_STARTED) {
                led_task_param_t param = {
                    .breathe = {
                        .red = 0x00,
                        .green = LED_ALL_DOORS
                    }
                };
                ledc_set_task(LED_BREATHE, param, 0);

                s_state = STATE_WIFI_PROVISIONING;
            }
#endif
            break;
#if !CONFIG_EMULATOR_MODE
        case STATE_WIFI_PROVISIONING:
            if (event->id == EVENT_PROVISION_WIFI_SUCCESS) {
                wifiprov_deinit();
                
                s_state = STATE_SYNCING_TIME;
                app_rtc_sync();

                ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                    .progress = {
                        .red = 0x00,
                        .green = LED_ALL_DOORS,
                        .progress = 2
                    }
                }, 0);

                s_provision_fail_ctr = 0;
                ESP_LOGI(TAG, "Wi-Fi provisioning success");
            } else if (event->id == EVENT_PROVISION_FAILED) {              
                ledc_set_task(LED_BLINK, (led_task_param_t) {
                    .blink = {
                        .red = LED_ALL_DOORS,
                        .green = 0x00
                    }
                }, 3000);

                s_provision_fail_ctr++;
                ESP_LOGW(TAG, "Wi-Fi provision failed, count = %d", s_provision_fail_ctr);

                if (s_provision_fail_ctr >= 3) {
                    ESP_ERROR_CHECK(supervisor_submit_event(EVENT_REBOOT_REQUESTED));
                }
            } else if (event->id == EVENT_LED_EFFECT_COMPLETE) {
                // Resume breathing
                led_task_param_t param = {
                    .breathe = {
                        .red = 0x00,
                        .green = LED_ALL_DOORS
                    }
                };
                ledc_set_task(LED_BREATHE, param, 0);
            }
            break;
#endif
        case STATE_CONNECTING_NETIF:
            if (event->id == EVENT_NETIF_CONNECTED) {
                s_state = STATE_SYNCING_TIME;
                app_rtc_sync();
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                ESP_LOGW(TAG, "Failed to connect to network. Retrying...");
                network_reconnect();
            }
            break;
        case STATE_SYNCING_TIME:
            if (event->id == EVENT_TIME_SYNCED) {
                ESP_LOGI(TAG, "RTC time synced");
                if (claim_has_credentials()) {
                    s_state = STATE_FETCHING_CERT;

#if !CONFIG_EMULATOR_MODE
                    ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                        .progress = {
                            .red = 0x00,
                            .green = LED_ALL_DOORS,
                            .progress = 3
                        }
                    }, 0);
#endif

                    claim_execute_fetch();
                } else {
#if CONFIG_EMULATOR_MODE
                    /* In emulator mode credentials arrive later via CLI.
                     * Stay in this state and wait. */
                    ESP_LOGI(TAG, "Waiting for claim credentials from engineering CLI...");
#else
                    // No claim credentials -- illegal state
                    provisioning_failed();
#endif
                }
            } else if (event->id == EVENT_CLAIM_CREDENTIALS_RECEIVED) {
                /* Credentials arrived (from CLI or BLE endpoint).
                 * If time is already synced we can proceed immediately. */
                if (claim_has_credentials()) {
                    s_state = STATE_FETCHING_CERT;
                    ESP_LOGI(TAG, "Claim credentials received, fetching temporary certificates...");
                    claim_execute_fetch();
                }
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                s_state = STATE_CONNECTING_NETIF;
                network_reconnect();
            }
            break;
        case STATE_FETCHING_CERT:
            if (event->id == EVENT_CERT_CLAIM_SUCCESS) {
                ESP_LOGI(TAG, "Claim certificate fetched successfully. Moving to STATE_FLEET_PROVISIONING.");
                s_state = STATE_FLEET_PROVISIONING;

#if !CONFIG_EMULATOR_MODE
                ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                    .progress = {
                        .red = 0x00,
                        .green = LED_ALL_DOORS,
                        .progress = 4
                    }
                }, 0);
#endif

                claim_fleet_provision();
            } else if (event->id == EVENT_CERT_CLAIM_FAILED) {
                ESP_LOGW(TAG, "Claim certificate fetch failed. Resetting provisioning and restarting.");
                provisioning_failed();
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                s_state = STATE_CONNECTING_NETIF;
                network_reconnect();
            }
            break;
        case STATE_FLEET_PROVISIONING:
            if(event->id == EVENT_FLEET_PROVISION_SUCCESS) {
                ESP_LOGI(TAG, "Fleet provision success!");
#if !CONFIG_EMULATOR_MODE
                ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                    .progress = {
                        .red = 0x00,
                        .green = LED_ALL_DOORS,
                        .progress = 7
                    }
                }, 3000);
#endif

                // Reboot when effect is complete
                ESP_ERROR_CHECK(supervisor_submit_event(EVENT_REBOOT_REQUESTED));
            } else if(event->id == EVENT_FLEET_PROVISION_FAILED) {
                ESP_LOGE(TAG, "Fleet provision failed!");
                provisioning_failed();
            } else if (event->id == EVENT_NETIF_DISCONNECTED) {
                s_state = STATE_CONNECTING_NETIF;
                network_reconnect();
            }
            break;
        default:
            break;
    }
}

void supervisor_provision_tick()
{

}
#include "supervisor_provision.h"
#include "wifi_provision.h"
#include "device_config.h"
#include "ledc.h"
#include <esp_log.h>
#include "network.h"
#include "claim.h"

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
    wifiprov_reset_provision();
    devcfg_reset_identity();

    // Blink red to indicate failure
    led_task_param_t param = {
        .blink = {
            .red = LED_ALL_DOORS,
            .green = 0x00
        }
    };
    ledc_set_task(LED_BLINK, param, 3000);

    ESP_ERROR_CHECK(supervisor_submit_event(EVENT_REBOOT_REQUESTED));
}

bool supervisor_provision_init()
{
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
}

void supervisor_provision_event(const supervisor_event_t* event)
{
    switch (s_state) {
        case STATE_INIT:
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
            break;
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

                    ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                        .progress = {
                            .red = 0x00,
                            .green = LED_ALL_DOORS,
                            .progress = 3
                        }
                    }, 0);

                    claim_execute_fetch();
                } else {
                    // No claim credentials -- illegal state
                    provisioning_failed();
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

                ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                    .progress = {
                        .red = 0x00,
                        .green = LED_ALL_DOORS,
                        .progress = 4
                    }
                }, 0);

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
                ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                    .progress = {
                        .red = 0x00,
                        .green = LED_ALL_DOORS,
                        .progress = 7
                    }
                }, 3000);

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
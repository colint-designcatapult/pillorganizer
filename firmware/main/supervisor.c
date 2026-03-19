#include "supervisor.h"
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "esp_log.h"
#include "esp_event.h"
#include "mux_io.h"
#include "network.h"
#include "wifi_provision.h"
#include "rtc.h"
#include "device_config.h"
#include "claim.h"
#include "fleet_provision.h"
#include "mqtt.h"

#define TAG "SUPERVISOR"

static QueueHandle_t s_supervisor_event_queue = NULL;

// Number of provision failures this boot
static uint8_t s_provision_fail_ctr = 0;

static bool supervisor_is_fully_provisioned()
{
    return wifiprov_is_provisioned() && devcfg_has_permanent_identity();
}

static void _Noreturn reset_provisioning(void) 
{
    wifiprov_reset_provision();
    devcfg_reset_identity();
    ESP_LOGI(TAG, "Provision state reset, restarting...");
    esp_restart();
}

static supervisor_state_t network_connect_success()
{
    app_rtc_sync();
    return STATE_SYNCING_TIME;
}



void supervisor_init()
{
    // Create event queue
    s_supervisor_event_queue = xQueueCreate(16, sizeof(supervisor_event_t));
    if (s_supervisor_event_queue == NULL) {
        ESP_ERROR_CHECK(ESP_ERR_NO_MEM);
    }

    ESP_LOGI(TAG, "Supervisor initialized");
}

void supervisor_run()
{
    supervisor_state_t current_state = STATE_INIT;
    supervisor_event_t event;
    bool event_received = false;

    if (wifiprov_is_provisioned()) {
        // Device provisioned with Wi-Fi Credentials, network stack is already connecting
        // network_wifi_init() / esp_wifi_start() uses provisioned credentials to connect
        if(devcfg_has_permanent_identity()) {
            current_state = STATE_CONNECTING_NETIF;
        } else {
            // Has Wi-Fi credentials, but no permanent identity
            // Must start over since it has no way of getting a claim cert
            reset_provisioning();
        }
    } else {
        wifiprov_start_provision();
        current_state = STATE_UNPROVISIONED;
    }

    while (1) {
        event_received = xQueueReceive(s_supervisor_event_queue, &event, pdMS_TO_TICKS(1000));

        if (event_received) {
            ESP_LOGI(TAG, "Received event: %d in state: %d", event.id, current_state);

            switch (current_state) {
                case STATE_UNPROVISIONED:
                    if (event.id == EVENT_PROVISION_STARTED) {
                        current_state = STATE_PROVISIONING;
                    }
                    break;
                case STATE_PROVISIONING:
                    if (event.id == EVENT_PROVISION_WIFI_SUCCESS) {
                        // At this point, provisioning is complete AND we are connected to Wi-Fi
                        wifiprov_deinit();
                        current_state = network_connect_success();
                        s_provision_fail_ctr = 0;
                        ESP_LOGI(TAG, "Wi-Fi provisioning success");
                    } else if (event.id == EVENT_PROVISION_FAILED) {              
                        // Provisioning failed, but the provision service stays running so we don't need to reset it

                        // Increment failure counter
                        s_provision_fail_ctr++;

                        ESP_LOGW(TAG, "Wi-Fi provision failed, count = %d", s_provision_fail_ctr);

                        // On 3 failures, restart the system
                        if (s_provision_fail_ctr >= 3) {
                            esp_restart();
                        }
                    }
                    break;
                case STATE_CONNECTING_NETIF:
                    //
                    // Wi-Fi connecting state, but does NOT include the connection during provisioning.
                    // 
                    if (event.id == EVENT_NETIF_CONNECTED) {
                        current_state = network_connect_success();
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        ESP_LOGW(TAG, "Failed to connect to network.");
                        // Let the esp_wifi_connect auto-retry logic in network.c handle it.
                    }
                    break;
                case STATE_SYNCING_TIME:
                    // System will always hit this state during init, even if time doesn't need to be synced
                    if (event.id == EVENT_TIME_SYNCED) {
                        ESP_LOGI(TAG, "RTC time synced");
                        if (devcfg_has_permanent_identity()) {
                            // No more initial provisioning to do. Device online and fully provisioned.
                            mqtt_init();
                            current_state = STATE_OPERATIONAL;
                        } else if (claim_has_credentials()) {
                            // Not fully provisioned, but we have claim credentials. Fetch temporary claim certs.
                            current_state = STATE_FETCHING_CERT;
                            claim_execute_fetch();
                        } else {
                            // Not fully provisioned, no claim credentials. Unrecoverable state. Reset device.
                            reset_provisioning();
                        }
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        current_state = STATE_CONNECTING_NETIF;
                    }
                    break;
                case STATE_FETCHING_CERT:
                    if (event.id == EVENT_CERT_CLAIM_SUCCESS) {
                        ESP_LOGI(TAG, "Claim certificate fetched successfully. Moving to STATE_FLEET_PROVISIONING.");
                        current_state = STATE_FLEET_PROVISIONING;
                        claim_fleet_provision();
                    } else if (event.id == EVENT_CERT_CLAIM_FAILED) {
                        ESP_LOGW(TAG, "Claim certificate fetch failed. Resetting provisioning and restarting.");
                        reset_provisioning();
                    }
                    break;
                case STATE_FLEET_PROVISIONING:
                    // Will handle Fleet Provisioning success/failure events here
                    if(event.id == EVENT_FLEET_PROVISION_SUCCESS) {
                        ESP_LOGI(TAG, "Fleet provision success!");
                        // Restart now, we just went through the entire provisioning flow
                        // Better to just start from a clean slate
                        esp_restart();
                    } else if(event.id == EVENT_FLEET_PROVISION_FAILED) {
                        ESP_LOGE(TAG, "Fleet provision failed!");
                        reset_provisioning();
                    }
                    break;
                case STATE_OPERATIONAL:
                    // Handle events during normal operation
                    if(event.id == EVENT_FLEET_PROVISION_DEINIT) {
                        // We just finished fleet provisioning
                    }
                    break;
                default:
                    break;
            }
        } else {
            // Periodic checks / timeout handling
        }
    }
}

esp_err_t supervisor_submit_event_block(supervisor_event_id_t event_id, void* payload, TickType_t ticks_to_wait)
{
    supervisor_event_t event = {
        .id = event_id,
        .payload = payload
    };

    if (xQueueSend(s_supervisor_event_queue, &event, ticks_to_wait) != pdPASS) {
        return ESP_ERR_NO_MEM;
    }
    return ESP_OK;
}

esp_err_t supervisor_submit_event(supervisor_event_id_t event_id)
{
    return supervisor_submit_event_block(event_id, NULL, 0);
}

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
#include "string.h"
#include "shadow_state.h"
#include "ledc.h"
#include "nvs_wrapper.h"

#define TAG "SUPERVISOR"

static QueueHandle_t s_supervisor_event_queue = NULL;

// Number of provision failures this boot
static uint8_t s_provision_fail_ctr = 0;

// Whether a reset is requested, survives restarts
RTC_NOINIT_ATTR uint32_t reset_pending;

// Define reset flags to random values to avoid flipping bits in RTC RAM
#define RESET_FLAG_FACTORY      0x47eb74d9
#define RESET_FLAG_WIFI         0x3ab1ac62

static supervisor_state_t provisioning_failed()
{
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

    return STATE_RESET_PENDING;
}

static supervisor_state_t network_connect_success()
{
    app_rtc_sync();
    return STATE_SYNCING_TIME;
}

static void supervisor_check_factory_reset()
{
    esp_reset_reason_t reason = esp_reset_reason();
    if (reason != ESP_RST_SW) {
        // The memory is full of random garbage right now. Safe to zero it.
        reset_pending = 0;
    }

    if (reset_pending == RESET_FLAG_FACTORY) {
        // Immediately reset the value
        reset_pending = 0;

        devcfg_reset_identity();
        nvs_factory_reset();
        esp_restart();
    }
}

static void supervisor_check_wifi_reset()
{
    if (reset_pending == RESET_FLAG_WIFI) {
        // Immediately reset the value
        reset_pending = 0;

        // Just reset Wi-Fi
        wifiprov_reset_provision();
        esp_restart();
    }
    // Unconditionally unset pending flag
    reset_pending = 0;
}

void supervisor_init()
{
    // Check if reset is requested and execute it if requested
    supervisor_check_factory_reset();

    // Create event queue
    s_supervisor_event_queue = xQueueCreate(16, sizeof(supervisor_event_t));
    if (s_supervisor_event_queue == NULL) {
        ESP_ERROR_CHECK(ESP_ERR_NO_MEM);
    }

    ESP_LOGI(TAG, "Supervisor initialized");
}

static void create_initial_device_state(device_state_t* state)
{
    memset(state, 0, sizeof(device_state_t));
    state->timestamp = app_rtc_get_relative_timestamp();
}

static void update_state(device_state_t* state)
{
    // Update state timestamp
    state->timestamp = app_rtc_get_relative_timestamp();
    supervisor_submit_event(EVENT_STATE_CHANGED);
}

static void send_state_update(device_state_t* state)
{
    mqtt_publish_device_state(state);
}

void supervisor_run()
{
    supervisor_state_t current_state = STATE_INIT;
    supervisor_event_t event;
    device_state_t device_state;
    bool event_received = false;

    // Check if Wi-Fi wants to be reset
    supervisor_check_wifi_reset();

    create_initial_device_state(&device_state);
    update_state(&device_state);

    if (wifiprov_is_provisioned()) {
        // Device provisioned with Wi-Fi Credentials, network stack is already connecting
        if(devcfg_has_permanent_identity()) {
            shadow_state_init();
            current_state = STATE_CONNECTING_NETIF;
        } else {
            current_state = provisioning_failed();
        }
    } else {
        wifiprov_start_provision();
        current_state = STATE_UNPROVISIONED;
    }

    while (1) {
        event_received = xQueueReceive(s_supervisor_event_queue, &event, pdMS_TO_TICKS(1000));

        if (event_received) {
            ESP_LOGI(TAG, "Received event: %d in state: %d", event.id, current_state);

            supervisor_event_door_t door_payload = (supervisor_event_door_t)event.payload;

            /* Handle events regardless of state */
            switch(event.id) {
                case EVENT_DOOR_OPENED:
                    ESP_LOGI(TAG, "Door %d opened", door_payload);
                    device_state.bins[door_payload].opened_at = app_rtc_get_relative_timestamp();
                    device_state.doors |= (1 << door_payload);
                    update_state(&device_state);
                    break;
                case EVENT_DOOR_CLOSED:
                    ESP_LOGI(TAG, "Door %d closed", door_payload);
                    device_state.bins[door_payload].closed_at = app_rtc_get_relative_timestamp();
                    device_state.doors &= ~(1 << door_payload);
                    update_state(&device_state);
                    break;
                default:
                    break;
            }

            switch (current_state) {
                case STATE_UNPROVISIONED:
                    if (event.id == EVENT_PROVISION_STARTED) {
                        led_task_param_t param = {
                            .breathe = {
                                .red = 0x00,
                                .green = LED_ALL_DOORS
                            }
                        };
                        ledc_set_task(LED_BREATHE, param, 0);

                        current_state = STATE_PROVISIONING;
                    }
                    break;
                case STATE_PROVISIONING:
                    if (event.id == EVENT_PROVISION_WIFI_SUCCESS) {
                        wifiprov_deinit();
                        current_state = network_connect_success();

                        ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                            .progress = {
                                .red = 0x00,
                                .green = LED_ALL_DOORS,
                                .progress = 2
                            }
                        }, 0);

                        s_provision_fail_ctr = 0;
                        ESP_LOGI(TAG, "Wi-Fi provisioning success");
                    } else if (event.id == EVENT_PROVISION_FAILED) {              
                        ledc_set_task(LED_BLINK, (led_task_param_t) {
                            .blink = {
                                .red = LED_ALL_DOORS,
                                .green = 0x00
                            }
                        }, 3000);

                        s_provision_fail_ctr++;
                        ESP_LOGW(TAG, "Wi-Fi provision failed, count = %d", s_provision_fail_ctr);

                        if (s_provision_fail_ctr >= 3) {
                            current_state = STATE_RESET_PENDING;
                        }
                    } else if (event.id == EVENT_LED_EFFECT_COMPLETE) {
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
                    if (event.id == EVENT_NETIF_CONNECTED) {
                        current_state = network_connect_success();
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        ESP_LOGW(TAG, "Failed to connect to network.");
                        network_reconnect();
                    }
                    break;
                case STATE_SYNCING_TIME:
                    if (event.id == EVENT_TIME_SYNCED) {
                        ESP_LOGI(TAG, "RTC time synced");
                        if (devcfg_has_permanent_identity()) {
                            current_state = STATE_MQTT_DISCONNECTED;
                            mqtt_init();
                        } else if (claim_has_credentials()) {
                            current_state = STATE_FETCHING_CERT;

                            ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                                .progress = {
                                    .red = 0x00,
                                    .green = LED_ALL_DOORS,
                                    .progress = 3
                                }
                            }, 0);

                            claim_execute_fetch();
                        } else {
                            current_state = provisioning_failed();
                        }
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        current_state = STATE_CONNECTING_NETIF;
                        network_reconnect();
                    }
                    break;
                case STATE_FETCHING_CERT:
                    if (event.id == EVENT_CERT_CLAIM_SUCCESS) {
                        ESP_LOGI(TAG, "Claim certificate fetched successfully. Moving to STATE_FLEET_PROVISIONING.");
                        current_state = STATE_FLEET_PROVISIONING;

                        ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                            .progress = {
                                .red = 0x00,
                                .green = LED_ALL_DOORS,
                                .progress = 4
                            }
                        }, 0);

                        claim_fleet_provision();
                    } else if (event.id == EVENT_CERT_CLAIM_FAILED) {
                        ESP_LOGW(TAG, "Claim certificate fetch failed. Resetting provisioning and restarting.");
                        current_state = provisioning_failed();
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        current_state = STATE_CONNECTING_NETIF;
                        network_reconnect();
                    }
                    break;
                case STATE_FLEET_PROVISIONING:
                    if(event.id == EVENT_FLEET_PROVISION_SUCCESS) {
                        ESP_LOGI(TAG, "Fleet provision success!");
                        ledc_set_task(LED_PROGRESS, (led_task_param_t) {
                            .progress = {
                                .red = 0x00,
                                .green = LED_ALL_DOORS,
                                .progress = 7
                            }
                        }, 6000);
                        current_state = STATE_RESET_PENDING;
                    } else if(event.id == EVENT_FLEET_PROVISION_FAILED) {
                        ESP_LOGE(TAG, "Fleet provision failed!");
                        current_state = provisioning_failed();
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        current_state = STATE_CONNECTING_NETIF;
                        network_reconnect();
                    }
                    break;
                case STATE_MQTT_DISCONNECTED:
                    if (event.id == EVENT_MQTT_CONNECTED) {
                        current_state = STATE_OPERATIONAL;
                        shadow_state_on_connect();
                        update_state(&device_state);
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        current_state = STATE_CONNECTING_NETIF;
                        network_reconnect();
                    }
                    break;
                case STATE_OPERATIONAL:
                    if(event.id == EVENT_STATE_CHANGED) {
                        send_state_update(&device_state);
                    } else if(event.id == EVENT_MQTT_DISCONNECTED) {
                        current_state = STATE_MQTT_DISCONNECTED;
                    } else if (event.id == EVENT_NETIF_DISCONNECTED) {
                        current_state = STATE_CONNECTING_NETIF;
                        network_reconnect();
                    }
                    break;
                case STATE_RESET_PENDING:
                    if (event.id == EVENT_LED_EFFECT_COMPLETE) {
                        // We were waiting for an LED effect to finish
                        // Perform restart
                        esp_restart();
                    }
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

void supervisor_reset_wifi()
{
    reset_pending = RESET_FLAG_WIFI;
    esp_restart();
}

void supervisor_factory_reset()
{
    reset_pending = RESET_FLAG_FACTORY;
    esp_restart();
}

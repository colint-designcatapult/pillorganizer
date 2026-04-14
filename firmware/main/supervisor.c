#include "supervisor.h"
#include "supervisor_operation.h"
#include "supervisor_provision.h"
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
#include "esp_task_wdt.h"

#define TAG "SUPERVISOR"

static QueueHandle_t s_supervisor_event_queue = NULL;
static EventGroupHandle_t s_supervisor_error_group = NULL;

// Whether a reset is requested, survives restarts
RTC_NOINIT_ATTR uint32_t reset_pending;

// Define reset flags to random values to avoid flipping bits in RTC RAM
#define RESET_FLAG_FACTORY      0x47eb74d9
#define RESET_FLAG_WIFI         0x3ab1ac62

typedef enum {
    STATE_PROVISIONING,
    STATE_OPERATIONAL,
    STATE_PENDING_REBOOT
} supervisor_state_t;

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

    // Create error flags
    s_supervisor_error_group = xEventGroupCreate();
    if (s_supervisor_error_group == NULL) {
        ESP_ERROR_CHECK(ESP_ERR_NO_MEM);
    }

    // Create event queue
    s_supervisor_event_queue = xQueueCreate(16, sizeof(supervisor_event_t));
    if (s_supervisor_event_queue == NULL) {
        ESP_ERROR_CHECK(ESP_ERR_NO_MEM);
    }

    ESP_LOGI(TAG, "Supervisor initialized");
}


void supervisor_run()
{
    supervisor_event_t event;
    bool event_received = false;

    // Check if Wi-Fi wants to be reset
    supervisor_check_wifi_reset();

    // Flag if the device is fully operational, or setup (provisioning)
    // Try to init the provisioning supervisor, returns true if needs provisioning
    supervisor_state_t current_state = supervisor_provision_init() ? STATE_PROVISIONING : STATE_OPERATIONAL;

    if (current_state == STATE_OPERATIONAL) {
        // Initialize the operational supervisor instead
        supervisor_operation_init();
    }

    // Subscribe main supervisor task to hardware watchdog
    ESP_ERROR_CHECK(esp_task_wdt_add(NULL));

    // Main event loop
    while (true) {
        esp_task_wdt_reset();
        event_received = xQueueReceive(s_supervisor_event_queue, &event, pdMS_TO_TICKS(1000));

        if (event_received) {
            ESP_LOGI(TAG, "Event received: %d. Supervisor state %s", event.id, 
                current_state == STATE_OPERATIONAL ? "OPERATIONAL" : "PROVISIONING");

            // Process unconditional events
            if (event.id == EVENT_REBOOT_REQUESTED) {
                current_state = STATE_PENDING_REBOOT;
#ifdef CONFIG_EMULATOR_MODE
                /* Guarantee EVENT_LED_EFFECT_COMPLETE arrives after this
                 * transition even if the ledc stub's task lost the race. */
                supervisor_submit_event(EVENT_LED_EFFECT_COMPLETE);
#endif
            }

            switch (current_state) {
                case STATE_PROVISIONING:
                    supervisor_provision_event(&event);
                    break;
                case STATE_OPERATIONAL:
                    supervisor_operation_event(&event);
                    break;
                case STATE_PENDING_REBOOT:
                    if (event.id == EVENT_LED_EFFECT_COMPLETE) {
                        esp_restart();
                    }
                    break;
                default:
                    ESP_ERROR_CHECK(ESP_ERR_INVALID_STATE);
                    break;
            }
        } else {
            // Timeout of 1 sec received
            // Pass to subordinate supervisor
            if (current_state == STATE_OPERATIONAL) {
                supervisor_operation_tick();
            } else if(current_state == STATE_PROVISIONING) {
                supervisor_provision_tick();
            } else {
                // nothing?
                // Should probably add a timeout here for reboot
            }
        }
    }
}

esp_err_t supervisor_submit_event_block(supervisor_event_id_t event_id, intptr_t payload, TickType_t ticks_to_wait)
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
    return supervisor_submit_event_block(event_id, 0, 0);
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

esp_err_t supervisor_get_schedule(device_schedule_t* sched)
{
    return supervisor_operation_get_schedule(sched);
}

void supervisor_assert_error(device_error_flag_t error)
{
    xEventGroupSetBits(s_supervisor_error_group, error);
    ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_ERROR_CONDITION, (intptr_t)error, 1000));
}

void supervisor_clear_error(device_error_flag_t error)
{
    xEventGroupClearBits(s_supervisor_error_group, error);
    ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_ERROR_CLEARED, (intptr_t)error, 0));
}

device_error_flag_t supervisor_get_error_flags()
{
    return (device_error_flag_t)xEventGroupGetBits(s_supervisor_error_group);
}
/* 
 * Supervisor
 * 
 */
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <esp_err.h>

/* --- CURRENT STATE --- */

typedef enum {
    STATE_INIT,
    STATE_UNPROVISIONED,
    STATE_PROVISIONING,
    STATE_CONNECTING_NETIF,
    STATE_SYNCING_TIME,
    STATE_FETCHING_CERT,
    STATE_FLEET_PROVISIONING,
    STATE_OPERATIONAL
} supervisor_state_t;

/* --- EVENTS (State Transition Edges) --- */

typedef enum {
    EVENT_PROVISION_STARTED,
    EVENT_PROVISION_WIFI_SUCCESS,
    EVENT_PROVISION_FAILED,
    EVENT_NETIF_CONNECTED,
    EVENT_NETIF_DISCONNECTED,
    EVENT_CLAIM_CREDENTIALS_RECEIVED,
    EVENT_CERT_CLAIM_SUCCESS,
    EVENT_CERT_CLAIM_FAILED,
    EVENT_TIME_SYNCED,
    EVENT_FLEET_PROVISION_SUCCESS,
    EVENT_FLEET_PROVISION_FAILED,
    EVENT_FLEET_PROVISION_DEINIT
} supervisor_event_id_t;

typedef struct {
    supervisor_event_id_t id;
    void* payload; // optional
} supervisor_event_t;

void supervisor_init();
void supervisor_run();

esp_err_t supervisor_submit_event_block(supervisor_event_id_t event_id, void* payload, TickType_t ticks_to_wait);
esp_err_t supervisor_submit_event(supervisor_event_id_t event_id);

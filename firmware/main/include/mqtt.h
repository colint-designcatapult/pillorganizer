#pragma once
#include <esp_err.h>
#include "supervisor.h"

esp_err_t mqtt_init();

// Subscribe to a topic. MQTT client must be connected.
esp_err_t mqtt_subscribe(const char* topic, int qos, int* out_id);

esp_err_t mqtt_publish(const char* topic, const char* payload, int len, int qos, int retain);

esp_err_t mqtt_publish_device_state(device_state_t* state);

/*
 * Attempts to publish all pending outbox entries that have not yet been
 * assigned an MQTT packet ID. Entries are popped only after their
 * corresponding MQTT_EVENT_PUBLISHED confirmations are received, so multiple
 * QoS-1 messages may be in flight at the same time.
 * Safe to call when MQTT is not yet connected (no-op in that case).
 */
void mqtt_drain_event_outbox(void);
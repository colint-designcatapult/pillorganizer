#pragma once
#include <esp_err.h>
#include "supervisor.h"
#include "event_outbox.h"

esp_err_t mqtt_init();

// Subscribe to a topic. MQTT client must be connected.
esp_err_t mqtt_subscribe(const char* topic, int qos, int* out_id);

esp_err_t mqtt_publish(const char* topic, const char* payload, int len, int qos, int retain);

esp_err_t mqtt_publish_device_state(device_state_t* state);

/*
 * Serialize a single outbox entry to JSON and publish it via MQTT QoS 1.
 * Builds the event topic from the provisioned thing name, serializes the
 * entry fields (including schedule_id for bin events), and returns the
 * client-assigned packet ID in *out_msg_id on success.
 *
 * dev_state_hint: optional pre-loaded persistent device state used for
 * schedule_id lookup on bin events.  Pass NULL to have the function load
 * it from NVS internally (one NVS read per call).  Callers draining
 * multiple entries should load the state once and pass a pointer here to
 * avoid repeated NVS reads.
 *
 * Returns ESP_ERR_INVALID_STATE if MQTT is not connected, ESP_ERR_NO_MEM
 * if the publish buffer is full, or another error on failure.
 */
esp_err_t mqtt_publish_event(const event_outbox_entry_t* entry,
                              const device_persistent_state_t* dev_state_hint,
                              int* out_msg_id);
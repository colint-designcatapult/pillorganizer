/**
 * Shadow State
 * 
 * Implements client-side AWS IoT Core Shadow State handling.
 */
#pragma once
#include <stddef.h>
#include <device_config.h>

void shadow_state_init();

// Called when connected to the AWS IoT Core MQTT broker to subscribe to shadow topics
void shadow_state_on_connect();
void shadow_state_on_data(const char* topic, size_t topic_len, const char* payload, size_t payload_len);
void shadow_state_on_subscribe(int sub_id);

esp_err_t shadow_state_report_schedule(const device_schedule_t* schedule);
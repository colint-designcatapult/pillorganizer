/**
 * Shadow State
 * 
 * Implements client-side AWS IoT Core Shadow State handling.
 */
#pragma once
#include <stddef.h>

void shadow_state_init();

// Called when connected to the AWS IoT Core MQTT broker to subscribe to shadow topics
void shadow_state_on_connect();
void shadow_state_on_data(const char* topic, size_t topic_len, const char* payload, size_t payload_len);
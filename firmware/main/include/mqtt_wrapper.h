#pragma once

#include "esp_err.h"
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <esp_event.h>

// Configuration struct for dynamic credential swapping
typedef struct {
    const char* client_id;              // Thing Name or MAC address
    const char* client_cert_pem;        // Claim Cert OR Permanent Cert
    const char* client_key_pem;         // Claim Key OR Permanent Key
    esp_event_handler_t event_handler;  // Where to send MQTT events
} mqtt_wrapper_config_t;

// --- Core API ---

// Initializes the client, starts the MQTT task
esp_err_t mqtt_wrapper_connect(const mqtt_wrapper_config_t* config);

// Disconnects the broker, stops the background task, and frees memory
esp_err_t mqtt_wrapper_disconnect(void);

// Publishes a message (thread-safe)
esp_err_t mqtt_wrapper_publish(const char* topic, const char* payload, int len, int qos, int retain);

// Subscribes to a topic (thread-safe)
esp_err_t mqtt_wrapper_subscribe(const char* topic, int qos);

// Checks if we are currently connected
bool mqtt_wrapper_is_connected(void);
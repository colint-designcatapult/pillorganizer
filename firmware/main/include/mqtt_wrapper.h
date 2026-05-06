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
    bool disable_clean_session;         // If true, broker preserves session state (QoS 1 subs persist)
} mqtt_wrapper_config_t;

// --- Core API ---

// Initializes the mqtt_wrapper module (creates internal mutex). Must be called
// before mqtt_wrapper_connect() or other mqtt_wrapper operations such as
// publish/subscribe. This is called by mqtt_init().
void mqtt_wrapper_init(void);

// Initializes the client, starts the MQTT task
esp_err_t mqtt_wrapper_connect(const mqtt_wrapper_config_t* config);

// Disconnects the broker, stops the background task, and frees memory
esp_err_t mqtt_wrapper_disconnect(void);

// Publishes a message and returns the client-assigned packet ID used for MQTT ACK correlation (thread-safe)
esp_err_t mqtt_wrapper_publish_with_id(const char* topic, const char* payload, int len, int qos, int retain, int* out_msg_id);

// Publishes a message (thread-safe)
esp_err_t mqtt_wrapper_publish(const char* topic, const char* payload, int len, int qos, int retain);

// Subscribes to a topic (thread-safe)
esp_err_t mqtt_wrapper_subscribe(const char* topic, int qos, int* out_id);

// Checks if we are currently connected
bool mqtt_wrapper_is_connected(void);
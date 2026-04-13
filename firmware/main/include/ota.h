/**
 * OTA Update Module
 *
 * Subscribes to AWS IoT Core Jobs MQTT topics, parses OTA job documents,
 * and executes firmware updates via esp_https_ota when the device is idle.
 */
#pragma once
#include <stddef.h>
#include <esp_err.h>

void ota_init();

/* Called when MQTT connects — subscribes to the Jobs notify-next topic. */
void ota_on_connect();

/* Called for every incoming MQTT message — filters and handles Jobs topics. */
void ota_on_data(const char* topic, size_t topic_len, const char* data, size_t data_len);

/* Called for every MQTT subscribe acknowledgement. */
void ota_on_subscribe(int sub_id);

/*
 * Execute a pending OTA update. Called by the supervisor tick when the device
 * is idle and a job has been received. Downloads, flashes, and reboots.
 */
void ota_execute();

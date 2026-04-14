/**
 * OTA Update Module
 *
 * Subscribes to AWS IoT Core Jobs MQTT topics, parses OTA job documents
 * (requiring "type":"ota", "url", and "version" fields), and executes
 * firmware updates via esp_https_ota in a dedicated worker task so the
 * supervisor event loop is never blocked.
 *
 * All state transitions happen exclusively inside the supervisor task.
 * MQTT callbacks only allocate an ota_job_t and post it as an event payload.
 */
#pragma once
#include <stddef.h>
#include <esp_err.h>
#include <jobs.h>

/* OTA subsystem state machine states. */
typedef enum {
    OTA_IDLE,
    OTA_JOB_RECEIVED,
    OTA_IN_PROGRESS,
    OTA_SUCCEEDED,
    OTA_FAILED,
} ota_state_t;

#define OTA_URL_MAX_LEN     2048
#define OTA_VERSION_MAX_LEN 32

/*
 * Heap-allocated job descriptor passed as EVENT_OTA_JOB_RECEIVED payload.
 * The supervisor event handler is responsible for freeing this struct.
 */
typedef struct {
    char job_id[JOBID_MAX_LENGTH + 1];
    char version[OTA_VERSION_MAX_LEN];
    char url[OTA_URL_MAX_LEN];
} ota_job_t;

/* Initialise OTA module state. Call once before any other function. */
void ota_init(void);

/* Called when MQTT connects — subscribes to Jobs notify-next and
 * start-next/accepted topics. */
void ota_on_connect(void);

/* Called for every incoming MQTT message — filters Jobs topics, allocates
 * an ota_job_t, and posts EVENT_OTA_JOB_RECEIVED to the supervisor queue.
 * Never writes module-level globals (safe to call from MQTT task). */
void ota_on_data(const char* topic, size_t topic_len, const char* data, size_t data_len);

/* Called for every MQTT subscribe acknowledgement. */
void ota_on_subscribe(int sub_id);

/*
 * Accept a validated OTA job from the supervisor event handler.
 * Copies job_id and url into module state, sets state to OTA_JOB_RECEIVED,
 * and subscribes to per-job update/accepted and update/rejected topics.
 * Must only be called from the supervisor task.
 */
void ota_accept_job(const ota_job_t* job);

/*
 * Execute the pending OTA job. Non-blocking — spawns a dedicated worker task
 * that calls esp_https_ota() and posts EVENT_OTA_COMPLETE or EVENT_OTA_FAILED
 * when done. Must only be called when state is OTA_JOB_RECEIVED.
 */
void ota_execute(void);

/*
 * Reject the pending job. Publishes IN_PROGRESS then FAILED sequentially.
 * Resets state to OTA_IDLE. Must only be called from the supervisor task.
 */
void ota_reject(void);

/*
 * Called by the supervisor when EVENT_OTA_COMPLETE is received.
 * Publishes SUCCEEDED job status and resets state to OTA_SUCCEEDED.
 */
void ota_on_complete(void);

/*
 * Called by the supervisor when EVENT_OTA_FAILED is received.
 * Publishes FAILED job status and resets state to OTA_IDLE.
 */
void ota_on_failed(void);

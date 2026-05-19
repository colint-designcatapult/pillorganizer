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
 * Copies job_id, version, and url into module state, sets state to OTA_JOB_RECEIVED.
 * Must only be called from the supervisor task.
 */
void ota_accept_job(const ota_job_t* job);

/*
 * Reject the pending job. Publishes IN_PROGRESS then FAILED sequentially.
 * Resets state to OTA_IDLE. Must only be called from the supervisor task.
 */
void ota_reject(void);

/*
 * Spawn a worker task to download and flash the firmware at job->url.
 * Non-blocking — the worker posts EVENT_OTA_COMPLETE or EVENT_OTA_FAILED to
 * the supervisor queue when done. Called by supervisor_ota after time sync.
 * Returns ESP_OK if the task was successfully created, error otherwise.
 */
esp_err_t ota_execute_job(const ota_job_t* job);

/*
 * Stores the currently accepted job (job_id, version, url) to NVS so that
 * supervisor_ota can consume it on the next boot.
 * Must only be called after ota_accept_job().
 */
esp_err_t ota_store_accepted_job_to_nvs(void);

/*
 * Publishes IN_PROGRESS status for the currently accepted job to MQTT.
 * Must only be called after ota_accept_job().
 */
void ota_publish_accepted_job_in_progress(void);

/*
 * Reads the pending OTA job from NVS into *out and erases the NVS entry.
 * Returns ESP_ERR_NOT_FOUND if no pending job exists.
 * Called by supervisor_ota_init() on boot.
 */
esp_err_t ota_load_and_clear_pending_job(ota_job_t* out);

/*
 * Writes a boot-validation entry to NVS so the operational supervisor can
 * report the job result to AWS IoT Core on the next MQTT connection.
 * Pass the target version on success, or an empty string ("") to force FAILED.
 * Called by supervisor_ota after a flash attempt.
 */
void ota_store_boot_validation(const char* job_id, const char* version);

#include "ota.h"
#include "mqtt.h"
#include "device_config.h"
#include "supervisor.h"
#include "nvs_wrapper.h"
#include <esp_log.h>
#include <esp_https_ota.h>
#include <esp_ota_ops.h>
#include <esp_app_desc.h>
#include <esp_http_client.h>
#include <esp_task_wdt.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <jobs.h>
#include <cJSON.h>

#define TAG "OTA"

/* Embedded AWS root CA — same cert used for MQTT */
extern const char root_ca_pem_start[] asm("_binary_root_ca_pem_start");
extern const char root_ca_pem_end[]   asm("_binary_root_ca_pem_end");

#define OTA_WORKER_STACK     8192
#define OTA_WORKER_PRIORITY  (tskIDLE_PRIORITY + 5)

/* NVS key used to persist a pending boot-validation job across reboots.
 * Written after a successful flash; read on the next boot to determine
 * whether to publish SUCCEEDED (new firmware booted) or FAILED (rollback). */
#define OTA_NVS_PENDING_KEY  "ota_pending_val"

/* Struct persisted to NVS after a successful flash. */
typedef struct {
    char job_id[JOBID_MAX_LENGTH + 1];
    char version[OTA_VERSION_MAX_LEN];
} ota_pending_val_t;

/* All active-job state is written exclusively from the supervisor task. */
static ota_state_t s_state               = OTA_IDLE;
static char        s_job_id[JOBID_MAX_LENGTH + 1];
static char        s_job_version[OTA_VERSION_MAX_LEN];
static char        s_job_url[OTA_URL_MAX_LEN];

static int s_notify_next_sub_id      = -1;
static int s_start_next_sub_id       = -1;
static int s_update_accepted_sub_id  = -1;
static int s_update_rejected_sub_id  = -1;

/*
 * Set by ota_init() when a pending-validation entry is found in NVS.
 * The job ID and status are published once MQTT connects in ota_on_connect().
 * Both fields are cleared after the publish.
 */
static char              s_boot_pending_job_id[JOBID_MAX_LENGTH + 1];
static JobCurrentStatus_t s_boot_pending_status;

/* ---------------------------------------------------------------------------
 * Internal helpers
 * -------------------------------------------------------------------------*/

/*
 * Publish a job status update for the given job ID.
 * Returns the MQTT message ID on success, -1 on error.
 * Must only be called from the supervisor task.
 */
static int publish_job_status(const char* job_id, JobCurrentStatus_t status)
{
    char thing_name[THINGNAME_MAX_LENGTH + 1];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name for job status update");
        return -1;
    }

    if (!job_id || job_id[0] == '\0') {
        ESP_LOGW(TAG, "No job ID provided, cannot publish status");
        return -1;
    }

    char topic[TOPIC_BUFFER_SIZE];
    size_t topic_len = 0;
    JobsStatus_t js = Jobs_Update(topic, sizeof(topic),
                                  thing_name, (uint16_t)strlen(thing_name),
                                  job_id, (uint16_t)strlen(job_id),
                                  &topic_len);
    if (js != JobsSuccess) {
        ESP_LOGE(TAG, "Jobs_Update topic generation failed: %d", js);
        return -1;
    }

    static const char * const status_str[] = {
        "QUEUED", "IN_PROGRESS", "FAILED", "SUCCEEDED", "REJECTED"
    };
    char msg[48];
    int msg_len = snprintf(msg, sizeof(msg), "{\"status\":\"%s\"}", status_str[status]);
    if (msg_len <= 0 || msg_len >= (int)sizeof(msg)) {
        ESP_LOGE(TAG, "Failed to build job status message");
        return -1;
    }

    int msg_id = -1;
    esp_err_t err = mqtt_publish_with_id(topic, msg, msg_len, 1, 0, &msg_id);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "Failed to publish job status %s: %d", status_str[status], err);
        return -1;
    }

    ESP_LOGI(TAG, "Job %s status published: %s (msg_id=%d)", job_id, status_str[status], msg_id);
    return msg_id;
}

/* Subscribe to the per-job update confirmation topics. */
static void subscribe_job_update_topics(const char* job_id)
{
    char thing_name[THINGNAME_MAX_LENGTH + 1];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name for per-job subscriptions");
        return;
    }

    char topic[TOPIC_BUFFER_SIZE];
    int written;

    written = snprintf(topic, sizeof(topic),
                       "$aws/things/%s/jobs/%s/update/accepted",
                       thing_name, job_id);
    if (written > 0 && written < (int)sizeof(topic)) {
        int sub_id = -1;
        esp_err_t err = mqtt_subscribe(topic, 1, &sub_id);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "Failed to subscribe update/accepted for job %s: %d", job_id, err);
        } else {
            s_update_accepted_sub_id = sub_id;
            ESP_LOGI(TAG, "Subscribed update/accepted for job %s (sub_id=%d)", job_id, sub_id);
        }
    } else {
        ESP_LOGE(TAG, "update/accepted topic too long for job %s", job_id);
    }

    written = snprintf(topic, sizeof(topic),
                       "$aws/things/%s/jobs/%s/update/rejected",
                       thing_name, job_id);
    if (written > 0 && written < (int)sizeof(topic)) {
        int sub_id = -1;
        esp_err_t err = mqtt_subscribe(topic, 1, &sub_id);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "Failed to subscribe update/rejected for job %s: %d", job_id, err);
        } else {
            s_update_rejected_sub_id = sub_id;
            ESP_LOGI(TAG, "Subscribed update/rejected for job %s (sub_id=%d)", job_id, sub_id);
        }
    } else {
        ESP_LOGE(TAG, "update/rejected topic too long for job %s", job_id);
    }
}

/* Reset all job state back to IDLE. */
static void reset_state(void)
{
    s_state       = OTA_IDLE;
    s_job_id[0]   = '\0';
    s_job_version[0] = '\0';
    s_job_url[0]  = '\0';
    s_update_accepted_sub_id = -1;
    s_update_rejected_sub_id = -1;
}

/* ---------------------------------------------------------------------------
 * OTA worker task — runs the blocking download in its own FreeRTOS task
 * -------------------------------------------------------------------------*/

static void ota_worker_task(void* arg)
{
    char* url = (char*)arg;

#if !CONFIG_EMULATOR_MODE
    esp_task_wdt_add(NULL);
#endif

    ESP_LOGI(TAG, "OTA worker task started: %s", url);

    esp_http_client_config_t http_cfg = {
        .url               = url,
        .cert_pem          = root_ca_pem_start,
        .keep_alive_enable = true,
        /* Pre-signed S3 URLs can be very long (1 KB+).  Increase both the
         * receive and transmit buffers so the HTTP client can encode the full
         * request line without hitting "Out of buffer". */
        .buffer_size       = 4096,
        .buffer_size_tx    = 4096,
    };
    esp_https_ota_config_t ota_cfg = {
        .http_config = &http_cfg,
    };

#if !CONFIG_EMULATOR_MODE
    esp_task_wdt_reset();
#endif
    esp_err_t err = esp_https_ota(&ota_cfg);
#if !CONFIG_EMULATOR_MODE
    esp_task_wdt_reset();
#endif

    free(url);

    if (err == ESP_OK) {
        ESP_LOGI(TAG, "OTA download and flash succeeded — notifying supervisor");
        esp_err_t post_err = supervisor_submit_event_block(
                EVENT_OTA_COMPLETE, 0, pdMS_TO_TICKS(5000));
        if (post_err != ESP_OK) {
            ESP_LOGE(TAG, "Failed to post EVENT_OTA_COMPLETE — rebooting");
            esp_restart();
        }
    } else {
        ESP_LOGE(TAG, "OTA failed: %s", esp_err_to_name(err));
        supervisor_submit_event_block(EVENT_OTA_FAILED, 0, pdMS_TO_TICKS(5000));
    }

#if !CONFIG_EMULATOR_MODE
    esp_task_wdt_delete(NULL);
#endif
    vTaskDelete(NULL);
}

/* ---------------------------------------------------------------------------
 * Public API
 * -------------------------------------------------------------------------*/

void ota_init(void)
{
    reset_state();
    s_notify_next_sub_id    = -1;
    s_start_next_sub_id     = -1;
    s_boot_pending_job_id[0] = '\0';
    s_boot_pending_status    = Succeeded;  /* default; overwritten below if needed */

    /* Check for a pending boot-validation job left by a previous flash.
     * This is written by ota_on_complete() before rebooting.
     * We determine success or failure by comparing the stored target version
     * against the firmware that is actually running now:
     *   - Match   → new firmware booted cleanly → will publish SUCCEEDED on MQTT connect.
     *   - Mismatch → bootloader rolled back to old firmware → will publish FAILED. */
    ota_pending_val_t pending = {0};
    esp_err_t nvs_err = nvs_read_blob(OTA_NVS_PENDING_KEY, &pending, sizeof(pending));
    if (nvs_err == ESP_OK && pending.job_id[0] != '\0') {
        const char* running_version = esp_app_get_description()->version;
        bool version_match = (strcmp(pending.version, running_version) == 0);

        memcpy(s_boot_pending_job_id, pending.job_id, sizeof(s_boot_pending_job_id));
        s_boot_pending_status = version_match ? Succeeded : Failed;

        /* Clear the NVS entry immediately — if we crash again before publishing,
         * a subsequent boot will not re-attempt the publish for the same job. */
        esp_err_t erase_err = nvs_erase_key_entry(OTA_NVS_PENDING_KEY);
        if (erase_err != ESP_OK) {
            ESP_LOGW(TAG, "Failed to erase NVS pending key: %d", erase_err);
        }

        if (version_match) {
            ESP_LOGI(TAG, "Boot validation: job %s succeeded (running %s)",
                     pending.job_id, running_version);
        } else {
            ESP_LOGW(TAG, "Boot validation: job %s FAILED — expected %s, running %s (rollback?)",
                     pending.job_id, pending.version, running_version);
        }
    }

    ESP_LOGI(TAG, "OTA module initialized");
}

void ota_on_connect(void)
{
    char thing_name[THINGNAME_MAX_LENGTH + 1];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name for Jobs subscription");
        return;
    }

    char topic[TOPIC_BUFFER_SIZE];
    size_t topic_len = 0;

    /* notify-next: fires when the next pending job changes */
    JobsStatus_t js = Jobs_GetTopic(topic, sizeof(topic),
                                    thing_name, (uint16_t)strlen(thing_name),
                                    JobsNextJobChanged,
                                    &topic_len);
    if (js != JobsSuccess) {
        ESP_LOGE(TAG, "Jobs_GetTopic (notify-next) failed: %d", js);
        return;
    }
    int sub_id = -1;
    esp_err_t err = mqtt_subscribe(topic, 1, &sub_id);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe Jobs notify-next: %d", err);
    } else {
        s_notify_next_sub_id = sub_id;
        ESP_LOGI(TAG, "Subscribed Jobs notify-next (sub_id=%d)", sub_id);
    }

    /* start-next/accepted: recovers jobs already QUEUED before a reboot */
    topic_len = 0;
    js = Jobs_GetTopic(topic, sizeof(topic),
                       thing_name, (uint16_t)strlen(thing_name),
                       JobsStartNextSuccess,
                       &topic_len);
    if (js != JobsSuccess) {
        ESP_LOGE(TAG, "Jobs_GetTopic (start-next/accepted) failed: %d", js);
        return;
    }
    sub_id = -1;
    err = mqtt_subscribe(topic, 1, &sub_id);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe Jobs start-next/accepted: %d", err);
    } else {
        s_start_next_sub_id = sub_id;
        ESP_LOGI(TAG, "Subscribed Jobs start-next/accepted (sub_id=%d)", sub_id);
    }

    /* Publish any deferred boot-validation status from a previous flash.
     * This fires exactly once per successful MQTT connection after a flash:
     *   SUCCEEDED if the new firmware is running, FAILED if the bootloader rolled back. */
    if (s_boot_pending_job_id[0] != '\0') {
        ESP_LOGI(TAG, "Publishing boot-validation status for job %s: %s",
                 s_boot_pending_job_id,
                 s_boot_pending_status == Succeeded ? "SUCCEEDED" : "FAILED");
        publish_job_status(s_boot_pending_job_id, s_boot_pending_status);
        s_boot_pending_job_id[0] = '\0';
    }
}

void ota_on_subscribe(int sub_id)
{
    if (sub_id == s_notify_next_sub_id) {
        ESP_LOGI(TAG, "Jobs notify-next subscription confirmed (sub_id=%d)", sub_id);
    }

    if (sub_id == s_start_next_sub_id) {
        ESP_LOGI(TAG, "Jobs start-next/accepted subscription confirmed — publishing StartNext");

        char thing_name[THINGNAME_MAX_LENGTH + 1];
        if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
            ESP_LOGE(TAG, "Could not retrieve thing name for StartNext request");
            return;
        }

        char topic[TOPIC_BUFFER_SIZE];
        size_t topic_len = 0;
        JobsStatus_t js = Jobs_StartNext(topic, sizeof(topic),
                                         thing_name, (uint16_t)strlen(thing_name),
                                         &topic_len);
        if (js != JobsSuccess) {
            ESP_LOGE(TAG, "Jobs_StartNext topic generation failed: %d", js);
            return;
        }

        char msg[START_JOB_MSG_LENGTH];
        size_t msg_len = Jobs_StartNextMsg(thing_name, strlen(thing_name),
                                           msg, sizeof(msg));
        if (msg_len == 0) {
            ESP_LOGE(TAG, "Jobs_StartNextMsg failed");
            return;
        }

        esp_err_t err = mqtt_publish(topic, msg, (int)msg_len, 1, 0);
        if (err != ESP_OK) {
            ESP_LOGW(TAG, "Failed to publish StartNext request: %d", err);
        } else {
            ESP_LOGI(TAG, "StartNext request published — checking for pending OTA job");
        }
    }

    if (sub_id == s_update_accepted_sub_id) {
        ESP_LOGI(TAG, "OTA update/accepted subscription confirmed (sub_id=%d)", sub_id);
    }

    if (sub_id == s_update_rejected_sub_id) {
        ESP_LOGI(TAG, "OTA update/rejected subscription confirmed (sub_id=%d)", sub_id);
    }
}

void ota_on_data(const char* topic, size_t topic_len, const char* data, size_t data_len)
{
    if (!topic || !data || topic_len == 0 || data_len == 0) return;
    if (topic_len < 4 || strncmp(topic, "$aws", 4) != 0) return;

    char thing_name[THINGNAME_MAX_LENGTH + 1];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) return;

    char topic_buf[TOPIC_BUFFER_SIZE];
    size_t copy_len = topic_len < sizeof(topic_buf) - 1 ? topic_len : sizeof(topic_buf) - 1;
    memcpy(topic_buf, topic, copy_len);
    topic_buf[copy_len] = '\0';

    /* Check for the per-job update/rejected confirmation topic.
     * s_job_id is read here from the MQTT task, but it is set by the
     * supervisor task in ota_accept_job() before the subscription is active,
     * and cleared only after the job ends — so this read is safe. */
    if (s_update_rejected_sub_id >= 0 && s_job_id[0] != '\0') {
        char rejected_topic[TOPIC_BUFFER_SIZE];
        int written = snprintf(rejected_topic, sizeof(rejected_topic),
                               "$aws/things/%s/jobs/%s/update/rejected",
                               thing_name, s_job_id);
        if (written > 0 && written < (int)sizeof(rejected_topic) &&
            copy_len == (size_t)written &&
            strncmp(topic_buf, rejected_topic, copy_len) == 0) {
            ESP_LOGE(TAG, "AWS rejected status update for job %s — resetting", s_job_id);
            supervisor_submit_event(EVENT_OTA_FAILED);
            return;
        }
    }

    /* Match Jobs notification topics */
    JobsTopic_t topic_type;
    char* out_job_id = NULL;
    uint16_t out_job_id_len = 0;
    JobsStatus_t js = Jobs_MatchTopic(topic_buf, copy_len,
                                      thing_name, (uint16_t)strlen(thing_name),
                                      &topic_type,
                                      &out_job_id, &out_job_id_len);
    if (js != JobsSuccess ||
        (topic_type != JobsNextJobChanged && topic_type != JobsStartNextSuccess)) return;

    cJSON* root = cJSON_ParseWithLength(data, data_len);
    if (!root) {
        ESP_LOGE(TAG, "Failed to parse Jobs notification JSON");
        return;
    }

    /* No "execution" field means no pending job — normal after completion. */
    cJSON* execution = cJSON_GetObjectItemCaseSensitive(root, "execution");
    if (!cJSON_IsObject(execution)) {
        ESP_LOGD(TAG, "Jobs notification: no pending job");
        cJSON_Delete(root);
        return;
    }

    cJSON* job_id_item = cJSON_GetObjectItemCaseSensitive(execution, "jobId");
    if (!cJSON_IsString(job_id_item) || job_id_item->valuestring[0] == '\0') {
        ESP_LOGW(TAG, "Jobs notification: jobId missing or empty");
        cJSON_Delete(root);
        return;
    }
    size_t job_id_len = strlen(job_id_item->valuestring);
    if (job_id_len > JOBID_MAX_LENGTH) {
        ESP_LOGE(TAG, "Jobs notification: jobId too long (%zu bytes)", job_id_len);
        cJSON_Delete(root);
        return;
    }

    cJSON* job_doc = cJSON_GetObjectItemCaseSensitive(execution, "jobDocument");
    if (!cJSON_IsObject(job_doc)) {
        ESP_LOGE(TAG, "OTA job document missing for job %s", job_id_item->valuestring);
        cJSON_Delete(root);
        return;
    }

    /* Validate "type": "ota" discriminator — silently ignore non-OTA jobs */
    cJSON* type_item = cJSON_GetObjectItemCaseSensitive(job_doc, "type");
    if (!cJSON_IsString(type_item) || strcmp(type_item->valuestring, "ota") != 0) {
        ESP_LOGD(TAG, "Job %s is not type 'ota' — ignoring", job_id_item->valuestring);
        cJSON_Delete(root);
        return;
    }

    cJSON* url_item = cJSON_GetObjectItemCaseSensitive(job_doc, "url");
    if (!cJSON_IsString(url_item) || url_item->valuestring[0] == '\0') {
        ESP_LOGE(TAG, "OTA job %s missing 'url' field", job_id_item->valuestring);
        cJSON_Delete(root);
        return;
    }
    size_t url_len = strlen(url_item->valuestring);
    if (url_len >= OTA_URL_MAX_LEN) {
        ESP_LOGE(TAG, "OTA URL too long (%zu bytes) for job %s", url_len, job_id_item->valuestring);
        cJSON_Delete(root);
        return;
    }

    cJSON* version_item = cJSON_GetObjectItemCaseSensitive(job_doc, "version");
    if (!cJSON_IsString(version_item) || version_item->valuestring[0] == '\0') {
        ESP_LOGE(TAG, "OTA job %s missing 'version' field", job_id_item->valuestring);
        cJSON_Delete(root);
        return;
    }
    size_t version_len = strlen(version_item->valuestring);
    if (version_len >= OTA_VERSION_MAX_LEN) {
        ESP_LOGE(TAG, "OTA version string too long for job %s", job_id_item->valuestring);
        cJSON_Delete(root);
        return;
    }

    /* Allocate job descriptor — ownership transfers to the supervisor task */
    ota_job_t* job = calloc(1, sizeof(ota_job_t));
    if (!job) {
        ESP_LOGE(TAG, "Failed to allocate ota_job_t — dropping job %s",
                 job_id_item->valuestring);
        cJSON_Delete(root);
        return;
    }
    memcpy(job->job_id, job_id_item->valuestring, job_id_len + 1);
    memcpy(job->url, url_item->valuestring, url_len + 1);
    memcpy(job->version, version_item->valuestring, version_len + 1);

    cJSON_Delete(root);

    ESP_LOGI(TAG, "OTA job parsed: id=%s version=%s — posting to supervisor",
             job->job_id, job->version);

    esp_err_t err = supervisor_submit_event_block(EVENT_OTA_JOB_RECEIVED,
                                                  (intptr_t)job,
                                                  pdMS_TO_TICKS(100));
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to post EVENT_OTA_JOB_RECEIVED: %d", err);
        free(job);
    }
}

void ota_accept_job(const ota_job_t* job)
{
    size_t id_len      = strlen(job->job_id);
    size_t url_len     = strlen(job->url);
    size_t version_len = strlen(job->version);

    if (id_len > JOBID_MAX_LENGTH || url_len >= OTA_URL_MAX_LEN ||
        version_len >= OTA_VERSION_MAX_LEN) {
        ESP_LOGE(TAG, "ota_accept_job: field exceeds maximum length");
        return;
    }

    memcpy(s_job_id,      job->job_id,  id_len      + 1);
    memcpy(s_job_url,     job->url,     url_len     + 1);
    memcpy(s_job_version, job->version, version_len + 1);
    s_state = OTA_JOB_RECEIVED;

    subscribe_job_update_topics(job->job_id);

    ESP_LOGI(TAG, "OTA job accepted: id=%s version=%s url=%s",
             job->job_id, job->version, job->url);
}

void ota_reject(void)
{
    if (s_job_id[0] == '\0') {
        ESP_LOGE(TAG, "ota_reject called but no job ID is stored");
        return;
    }

    ESP_LOGI(TAG, "Rejecting job %s — publishing IN_PROGRESS then FAILED", s_job_id);
    publish_job_status(s_job_id, InProgress);
    publish_job_status(s_job_id, Failed);

    reset_state();
}

void ota_execute(void)
{
    if (s_state != OTA_JOB_RECEIVED || s_job_url[0] == '\0' || s_job_id[0] == '\0') {
        ESP_LOGE(TAG, "ota_execute called in unexpected state (state=%d)", (int)s_state);
        return;
    }

    ESP_LOGI(TAG, "Executing OTA job %s — spawning worker task", s_job_id);

    /* Publish IN_PROGRESS before spawning the task */
    publish_job_status(s_job_id, InProgress);

    char* url_copy = strdup(s_job_url);
    if (!url_copy) {
        ESP_LOGE(TAG, "Failed to allocate URL for OTA worker task");
        publish_job_status(s_job_id, Failed);
        reset_state();
        return;
    }

    BaseType_t ret = xTaskCreate(ota_worker_task, "ota_worker",
                                 OTA_WORKER_STACK, url_copy,
                                 OTA_WORKER_PRIORITY, NULL);
    if (ret != pdPASS) {
        ESP_LOGE(TAG, "Failed to create OTA worker task");
        free(url_copy);
        publish_job_status(s_job_id, Failed);
        reset_state();
        return;
    }

    s_state = OTA_IN_PROGRESS;
    ESP_LOGI(TAG, "OTA worker task spawned — state → IN_PROGRESS");
}

void ota_on_complete(void)
{
    ESP_LOGI(TAG, "OTA flash succeeded for job %s — persisting to NVS, rebooting to validate",
             s_job_id);

    /* Persist the job ID and target version to NVS.
     * SUCCEEDED will only be published after the new firmware successfully
     * boots and connects to MQTT (see ota_init() + ota_on_connect()).
     * If the bootloader rolls back, FAILED will be published instead. */
    ota_pending_val_t pending;
    memset(&pending, 0, sizeof(pending));
    memcpy(pending.job_id,  s_job_id,      strlen(s_job_id)      + 1);
    memcpy(pending.version, s_job_version, strlen(s_job_version) + 1);

    esp_err_t err = nvs_write_blob(OTA_NVS_PENDING_KEY, &pending, sizeof(pending));
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to persist OTA pending validation to NVS: %d — "
                 "job status may not be reported", err);
    }

    s_state = OTA_SUCCEEDED;
    /* Caller (supervisor) submits EVENT_REBOOT_REQUESTED */
}

void ota_on_failed(void)
{
    ESP_LOGE(TAG, "OTA failed for job %s — resetting state", s_job_id);
    publish_job_status(s_job_id, Failed);
    reset_state();
}

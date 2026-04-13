#include "ota.h"
#include "mqtt.h"
#include "device_config.h"
#include "supervisor.h"
#include <esp_log.h>
#include <esp_https_ota.h>
#include <esp_ota_ops.h>
#include <esp_http_client.h>
#include <stdio.h>
#include <string.h>
#include <jobs.h>
#include <cJSON.h>

#define TAG "OTA"

/* Embedded AWS root CA — same cert used for MQTT */
extern const char root_ca_pem_start[] asm("_binary_root_ca_pem_start");
extern const char root_ca_pem_end[]   asm("_binary_root_ca_pem_end");

#define OTA_URL_MAX_LEN     512
#define OTA_VERSION_MAX_LEN 32

static char s_job_url[OTA_URL_MAX_LEN];
static char s_job_id[JOBID_MAX_LENGTH + 1];
static char s_job_version[OTA_VERSION_MAX_LEN];
static int  s_notify_next_sub_id = -1;
static int  s_start_next_sub_id  = -1;

/* Publish a job status update via the Jobs SDK.
 *
 * expectedVersion is intentionally omitted from the update message.
 * Jobs_UpdateMsg requires it, but including it causes VersionMismatch
 * rejections after the first update (each accepted update increments the
 * server-side version).  The AWS IoT Jobs API treats expectedVersion as
 * optional, so we build the minimal JSON body ourselves. */
static void publish_job_status(JobCurrentStatus_t status)
{
    char thing_name[THINGNAME_MAX_LENGTH + 1];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name for job status update");
        return;
    }

    if (s_job_id[0] == '\0') {
        ESP_LOGW(TAG, "No job ID stored, cannot publish status");
        return;
    }

    /* Build the update topic */
    char topic[TOPIC_BUFFER_SIZE];
    size_t topic_len = 0;
    JobsStatus_t js = Jobs_Update(topic, sizeof(topic),
                                  thing_name, (uint16_t)strlen(thing_name),
                                  s_job_id, (uint16_t)strlen(s_job_id),
                                  &topic_len);
    if (js != JobsSuccess) {
        ESP_LOGE(TAG, "Jobs_Update topic generation failed: %d", js);
        return;
    }

    /* Status strings mirror the JobCurrentStatus_t enum order in the SDK. */
    static const char * const status_str[] = {
        "QUEUED", "IN_PROGRESS", "FAILED", "SUCCEEDED", "REJECTED"
    };
    char msg[48];
    int msg_len = snprintf(msg, sizeof(msg), "{\"status\":\"%s\"}", status_str[status]);
    if (msg_len <= 0 || msg_len >= (int)sizeof(msg)) {
        ESP_LOGE(TAG, "Failed to build job status message");
        return;
    }

    esp_err_t err = mqtt_publish(topic, msg, msg_len, 1, 0);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "Failed to publish job status %d: %d", (int)status, err);
    } else {
        ESP_LOGI(TAG, "Job %s status published: %d", s_job_id, (int)status);
    }
}

void ota_init()
{
    s_job_url[0]     = '\0';
    s_job_id[0]      = '\0';
    s_job_version[0] = '\0';
    s_notify_next_sub_id = -1;
    s_start_next_sub_id  = -1;
    ESP_LOGI(TAG, "OTA module initialized");
}

void ota_on_connect()
{
    char thing_name[THINGNAME_MAX_LENGTH + 1];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name for Jobs subscription");
        return;
    }

    char topic[TOPIC_BUFFER_SIZE];
    size_t topic_len = 0;
    JobsStatus_t js = Jobs_GetTopic(topic, sizeof(topic),
                                    thing_name, (uint16_t)strlen(thing_name),
                                    JobsNextJobChanged,
                                    &topic_len);
    if (js != JobsSuccess) {
        ESP_LOGE(TAG, "Jobs_GetTopic failed: %d", js);
        return;
    }

    int sub_id = -1;
    esp_err_t err = mqtt_subscribe(topic, 1, &sub_id);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe to Jobs notify-next topic: %d", err);
    } else {
        s_notify_next_sub_id = sub_id;
        ESP_LOGI(TAG, "Subscribed to Jobs notify-next topic (sub_id=%d)", sub_id);
    }

    /* Also subscribe to start-next/accepted so we can recover any job that was
     * already QUEUED before a reboot (notify-next only fires on state changes). */
    topic_len = 0;
    js = Jobs_GetTopic(topic, sizeof(topic),
                       thing_name, (uint16_t)strlen(thing_name),
                       JobsStartNextSuccess,
                       &topic_len);
    if (js != JobsSuccess) {
        ESP_LOGE(TAG, "Jobs_GetTopic (StartNextSuccess) failed: %d", js);
        return;
    }

    sub_id = -1;
    err = mqtt_subscribe(topic, 1, &sub_id);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe to Jobs start-next/accepted topic: %d", err);
    } else {
        s_start_next_sub_id = sub_id;
        ESP_LOGI(TAG, "Subscribed to Jobs start-next/accepted topic (sub_id=%d)", sub_id);
    }
}

void ota_on_subscribe(int sub_id)
{
    if (sub_id == s_notify_next_sub_id) {
        ESP_LOGI(TAG, "Jobs notify-next subscription confirmed (sub_id=%d)", sub_id);
    }

    if (sub_id == s_start_next_sub_id) {
        ESP_LOGI(TAG, "Jobs start-next/accepted subscription confirmed (sub_id=%d)", sub_id);

        /* Subscription is live — now request the next pending job.
         * This recovers any job that was QUEUED before a reboot and would
         * never trigger a notify-next event on its own. */
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
}

void ota_on_data(const char* topic, size_t topic_len, const char* data, size_t data_len)
{
    if (!topic || !data || topic_len == 0 || data_len == 0) return;

    /* Quick prefix check — Jobs topics all start with "$aws" */
    if (topic_len < 4 || strncmp(topic, "$aws", 4) != 0) return;

    char thing_name[THINGNAME_MAX_LENGTH + 1];
    if (!devcfg_get_thing_name_str(thing_name, sizeof(thing_name))) return;

    /* Jobs_MatchTopic requires a mutable buffer */
    char topic_buf[TOPIC_BUFFER_SIZE];
    size_t copy_len = topic_len < sizeof(topic_buf) - 1 ? topic_len : sizeof(topic_buf) - 1;
    memcpy(topic_buf, topic, copy_len);
    topic_buf[copy_len] = '\0';

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

    /* When there is no pending job, AWS sends a notification with no
     * "execution" field (e.g. after a job completes or fails).  This is
     * normal — log at debug level and return cleanly. */
    cJSON* execution = cJSON_GetObjectItemCaseSensitive(root, "execution");
    if (!cJSON_IsObject(execution)) {
        ESP_LOGD(TAG, "Jobs notification: no pending job (no execution field)");
        cJSON_Delete(root);
        return;
    }

    cJSON* job_id_item = cJSON_GetObjectItemCaseSensitive(execution, "jobId");
    if (!cJSON_IsString(job_id_item) || job_id_item->valuestring[0] == '\0') {
        ESP_LOGW(TAG, "Jobs notification: execution.jobId missing or empty");
        cJSON_Delete(root);
        return;
    }
    size_t job_id_len = strlen(job_id_item->valuestring);
    if (job_id_len > JOBID_MAX_LENGTH) {
        ESP_LOGE(TAG, "Jobs notification: jobId too long (%zu bytes)", job_id_len);
        cJSON_Delete(root);
        return;
    }
    memcpy(s_job_id, job_id_item->valuestring, job_id_len + 1);

    cJSON* job_doc = cJSON_GetObjectItemCaseSensitive(execution, "jobDocument");
    if (!cJSON_IsObject(job_doc)) {
        ESP_LOGE(TAG, "OTA job document missing — ignoring job %s", s_job_id);
        s_job_id[0] = '\0';
        cJSON_Delete(root);
        return;
    }

    cJSON* url_item = cJSON_GetObjectItemCaseSensitive(job_doc, "url");
    if (!cJSON_IsString(url_item) || url_item->valuestring[0] == '\0') {
        ESP_LOGE(TAG, "OTA job document missing 'url' field — ignoring job %s", s_job_id);
        s_job_id[0] = '\0';
        cJSON_Delete(root);
        return;
    }
    size_t url_len = strlen(url_item->valuestring);
    if (url_len >= OTA_URL_MAX_LEN) {
        ESP_LOGE(TAG, "OTA URL too long (%zu bytes) — ignoring job %s", url_len, s_job_id);
        s_job_id[0] = '\0';
        cJSON_Delete(root);
        return;
    }
    memcpy(s_job_url, url_item->valuestring, url_len + 1);

    cJSON* ver_item = cJSON_GetObjectItemCaseSensitive(job_doc, "version");
    if (cJSON_IsString(ver_item) && ver_item->valuestring[0] != '\0') {
        size_t ver_len = strlen(ver_item->valuestring);
        if (ver_len < OTA_VERSION_MAX_LEN) {
            memcpy(s_job_version, ver_item->valuestring, ver_len + 1);
        } else {
            s_job_version[0] = '\0';
        }
    } else {
        s_job_version[0] = '\0';
    }

    cJSON_Delete(root);

    ESP_LOGI(TAG, "OTA job received: id=%s version=%s url=%s",
             s_job_id, s_job_version[0] ? s_job_version : "(unset)", s_job_url);

    supervisor_submit_event(EVENT_OTA_JOB_RECEIVED);
}

void ota_execute()
{
    if (s_job_url[0] == '\0') {
        ESP_LOGE(TAG, "ota_execute called but no URL is stored");
        return;
    }

    ESP_LOGI(TAG, "Starting OTA update: %s", s_job_url);
    publish_job_status(InProgress);

    esp_http_client_config_t http_cfg = {
        .url      = s_job_url,
        .cert_pem = root_ca_pem_start,
        .keep_alive_enable = true,
    };
    esp_https_ota_config_t ota_cfg = {
        .http_config = &http_cfg,
    };

    esp_err_t err = esp_https_ota(&ota_cfg);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "OTA download and flash succeeded — rebooting");
        publish_job_status(Succeeded);
        supervisor_submit_event(EVENT_OTA_COMPLETE);
        supervisor_submit_event(EVENT_REBOOT_REQUESTED);
    } else {
        ESP_LOGE(TAG, "OTA failed: %s", esp_err_to_name(err));
        publish_job_status(Failed);
        supervisor_submit_event(EVENT_OTA_FAILED);
        /* Clear stored state so the module is ready for a retry job */
        s_job_url[0] = '\0';
        s_job_id[0]  = '\0';
    }
}

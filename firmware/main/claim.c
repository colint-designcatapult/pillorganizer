#include "claim.h"
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_log.h>
#include <cJSON.h>
#include <esp_http_client.h>
#include <esp_crt_bundle.h>
#include "device_config.h"
#include "fleet_provision.h"
#include "supervisor.h"


#define TAG "Claim"

#define CONTROL_PLANE_BASE_URL "https://control-plane.app.healthesolutions.ca"
#define HTTP_RESPONSE_BUF_SIZE 8192

static QueueHandle_t s_claim_mutex = NULL;
static TaskHandle_t s_claim_task = NULL;
static char* s_claim_id = NULL;
static char* s_claim_token = NULL;
static char* s_claim_cert_pem = NULL;
static char* s_claim_key_pem = NULL;

static void claim_fetch_cert_task(void* param_raw);

void claim_init()
{
    s_claim_mutex = xSemaphoreCreateMutex();
}

bool claim_has_credentials()
{
    xSemaphoreTake(s_claim_mutex, portMAX_DELAY);
    bool creds = s_claim_id != NULL && s_claim_token != NULL;
    xSemaphoreGive(s_claim_mutex);
    return creds;
}

void claim_set_credentials(const char* claim_id, const char* claim_token)
{
    xSemaphoreTake(s_claim_mutex, portMAX_DELAY);

    if(s_claim_id != NULL) {
        free(s_claim_id);
    }

    if(s_claim_token != NULL) {
        free(s_claim_token);
    }

    s_claim_id = strdup(claim_id);
    s_claim_token = strdup(claim_token);

    xSemaphoreGive(s_claim_mutex);
}

void claim_execute_fetch()
{
    if (claim_has_credentials()) {
        xSemaphoreTake(s_claim_mutex, portMAX_DELAY);
        if(s_claim_task == NULL) {
            xTaskCreate(claim_fetch_cert_task, "claim_fetch_cert_task", 4096, NULL, 5, &s_claim_task);
        }
        xSemaphoreGive(s_claim_mutex);

    } else {
        supervisor_submit_event(EVENT_CERT_CLAIM_FAILED);
    }

}

// POST to control plane to get temporary certificates for Fleet Provisioning.
// Caller must free *cert_pem_out and *key_pem_out on success.
static esp_err_t fetch_temp_certs(const char* serial_number,
                                  const char* c_claim_id,
                                  const char* c_claim_token,
                                  char** cert_pem_out,
                                  char** key_pem_out)
{
    esp_err_t err = ESP_FAIL;
    char *body_str = NULL;
    char *resp_buf = NULL;
    cJSON *response = NULL;
    esp_http_client_handle_t client = NULL;

    *cert_pem_out = NULL;
    *key_pem_out  = NULL;

    ESP_LOGI(TAG, "fetch_temp_certs: sending claim credentials for Serial: %s", serial_number);

    // 1. Build JSON body
    cJSON *body_json = cJSON_CreateObject();
    cJSON_AddStringToObject(body_json, "serialNumber", serial_number);
    cJSON_AddStringToObject(body_json, "claimId",      c_claim_id);
    cJSON_AddStringToObject(body_json, "claimToken",   c_claim_token);
    body_str = cJSON_PrintUnformatted(body_json);
    cJSON_Delete(body_json);
    if (!body_str) return ESP_ERR_NO_MEM;

    // 2. Configure HTTP Client (NO event_handler needed)
    esp_http_client_config_t config = {
        .url               = CONTROL_PLANE_BASE_URL "/device/claim_cert",
        .method            = HTTP_METHOD_POST,
        .timeout_ms        = 30000,
        .crt_bundle_attach = esp_crt_bundle_attach,
    };

    client = esp_http_client_init(&config);
    if (!client) { err = ESP_ERR_NO_MEM; goto cleanup; }

    esp_http_client_set_header(client, "Content-Type", "application/json");

    // 3. Synchronous Request Execution
    err = esp_http_client_open(client, strlen(body_str));
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to open HTTP connection: %s", esp_err_to_name(err));
        goto cleanup;
    }

    int wlen = esp_http_client_write(client, body_str, strlen(body_str));
    if (wlen < 0) {
        ESP_LOGE(TAG, "Write failed");
        err = ESP_FAIL;
        goto cleanup;
    }

    esp_http_client_fetch_headers(client);
    int status = esp_http_client_get_status_code(client);
    if (status != 200) {
        ESP_LOGE(TAG, "HTTP status %d", status);
        err = ESP_FAIL;
        goto cleanup;
    }

    // 4. Synchronous Read Loop
    resp_buf = (char *)calloc(1, HTTP_RESPONSE_BUF_SIZE);
    if (!resp_buf) { err = ESP_ERR_NO_MEM; goto cleanup; }

    int total_read = 0;
    while (1) {
        // Read directly into our buffer, offsetting by what we've already read
        int read_len = esp_http_client_read_response(client, resp_buf + total_read, HTTP_RESPONSE_BUF_SIZE - total_read - 1);
        if (read_len < 0) {
            ESP_LOGE(TAG, "Error reading response");
            err = ESP_FAIL;
            goto cleanup;
        }
        if (read_len == 0) break; // Finished reading
        
        total_read += read_len;
        if (total_read >= HTTP_RESPONSE_BUF_SIZE - 1) {
            ESP_LOGE(TAG, "Response too large for buffer");
            err = ESP_FAIL;
            goto cleanup;
        }
    }
    resp_buf[total_read] = '\0';

    // 5. Parse Response
    response = cJSON_Parse(resp_buf);
    if (!response) {
        ESP_LOGE(TAG, "Invalid JSON response");
        err = ESP_FAIL;
        goto cleanup;
    }

    cJSON *cert_pem = cJSON_GetObjectItem(response, "certificatePem");
    cJSON *priv_key = cJSON_GetObjectItem(response, "privateKey");

    if (!cJSON_IsString(cert_pem) || !cJSON_IsString(priv_key)) {
        ESP_LOGE(TAG, "Missing credentials in response");
        err = ESP_FAIL;
        goto cleanup;
    }

    // 6. Extract Outputs
    *cert_pem_out = strdup(cert_pem->valuestring);
    *key_pem_out  = strdup(priv_key->valuestring);

    if (!*cert_pem_out || !*key_pem_out) {
        ESP_LOGE(TAG, "Memory allocation failed for cert/key outputs");
        err = ESP_ERR_NO_MEM;
        goto cleanup;
    }

    ESP_LOGI(TAG, "✓ Temp cert (%zu bytes) and key (%zu bytes) received successfully", 
             strlen(*cert_pem_out), strlen(*key_pem_out));
    err = ESP_OK;

cleanup:
    // Safely free everything
    if (body_str) free(body_str);
    if (resp_buf) free(resp_buf);
    if (response) cJSON_Delete(response);
    if (client) {
        esp_http_client_close(client); // Required when using _open() instead of _perform()
        esp_http_client_cleanup(client);
    }

    // Nullify outputs if we failed halfway through
    if (err != ESP_OK) {
        free(*cert_pem_out);
        free(*key_pem_out);
        *cert_pem_out = NULL;
        *key_pem_out  = NULL;
    }

    return err;
}

static void claim_fetch_cert_task(void* param_raw)
{
    esp_err_t err;

    char sn[SERIAL_NUMBER_STR_SIZE];
    devcfg_get_serial_number_str(sn, sizeof(sn));

    ESP_LOGI(TAG, "Fetching temp certs");

    for(int i = 0; i < 5; i++) {
        xSemaphoreTake(s_claim_mutex, portMAX_DELAY);
        if (s_claim_id == NULL || s_claim_token == NULL) {
            ESP_LOGE(TAG, "Claim credentials missing, cannot fetch temp certs");
            err = ESP_FAIL; 
        } else {
            err = fetch_temp_certs(sn, s_claim_id, s_claim_token, &s_claim_cert_pem, &s_claim_key_pem);
        }
        xSemaphoreGive(s_claim_mutex);
        if(err == ESP_OK) break;
        int seconds = i * (i + 5); // Rudimentary exponential backoff
        ESP_LOGW(TAG, "Claim fetch attempt %d failed, retrying in %d seconds...", i + 1, seconds);
        vTaskDelay(pdMS_TO_TICKS(1000 * seconds)); 
    }

    xSemaphoreTake(s_claim_mutex, portMAX_DELAY);
    s_claim_task = NULL;
    if (err != ESP_OK) {
        if(s_claim_cert_pem != NULL) free(s_claim_cert_pem);
        if(s_claim_key_pem  != NULL) free(s_claim_key_pem);
        s_claim_cert_pem = NULL;
        s_claim_key_pem  = NULL;

        if(s_claim_id != NULL) free(s_claim_id);
        if(s_claim_token != NULL) free(s_claim_token);
        s_claim_id = NULL;
        s_claim_token = NULL;
    }
    xSemaphoreGive(s_claim_mutex);

    if (err != ESP_OK) {
        // Failed -- HTTP request did not succeed
        ESP_LOGW(TAG, "Claim fetch failed: %s", esp_err_to_name(err));
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_CERT_CLAIM_FAILED));
    } else {
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_CERT_CLAIM_SUCCESS));
    }
    
    vTaskDelete(NULL);
}

void claim_fleet_provision()
{
    ESP_ERROR_CHECK(fleet_provision_start(s_claim_cert_pem, s_claim_key_pem, s_claim_id, s_claim_token));
}
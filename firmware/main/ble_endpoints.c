#include "ble_endpoints.h"
#include "wifi.h"
#include "esp_log.h"
#include "cJSON.h"
#include <string.h>
#include <stdlib.h>

#define TAG "BLEEndpoints"

// --- State ---

static char s_claim_id[128] = {0};
static char s_claim_token[256] = {0};
static bool s_claim_credentials_received = false;
static fleet_prov_status_t s_fleet_prov_status = FLEET_PROV_STATUS_IDLE;

// --- Endpoint Handlers ---

esp_err_t ble_endpoint_device_serial(uint32_t session_id,
                                      const uint8_t *inbuf, ssize_t inlen,
                                      uint8_t **outbuf, ssize_t *outlen,
                                      void *priv_data)
{
    ESP_LOGI(TAG, "=== device_serial_handler CALLED ===");
    ESP_LOGI(TAG, "Session ID: %lu, Input length: %zd", session_id, inlen);

    const wifi_info_t* wifi_info = wifi_get_info();
    if (!wifi_info) {
        ESP_LOGE(TAG, "Failed to get wifi_info");
        return ESP_FAIL;
    }
    ESP_LOGI(TAG, "Got wifi_info, MAC: %02X:%02X:%02X:%02X:%02X:%02X",
             wifi_info->sn.bytes.mac[0], wifi_info->sn.bytes.mac[1],
             wifi_info->sn.bytes.mac[2], wifi_info->sn.bytes.mac[3],
             wifi_info->sn.bytes.mac[4], wifi_info->sn.bytes.mac[5]);

    char serial_number[32];
    snprintf(serial_number, sizeof(serial_number), "ESP32-%02X%02X%02X%02X%02X%02X",
             wifi_info->sn.bytes.mac[0], wifi_info->sn.bytes.mac[1],
             wifi_info->sn.bytes.mac[2], wifi_info->sn.bytes.mac[3],
             wifi_info->sn.bytes.mac[4], wifi_info->sn.bytes.mac[5]);

    cJSON *response = cJSON_CreateObject();
    if (!response) {
        ESP_LOGE(TAG, "Failed to create JSON response for device_serial");
        return ESP_FAIL;
    }
    cJSON_AddStringToObject(response, "serialNumber", serial_number);

    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    if (!json_string) {
        ESP_LOGE(TAG, "Failed to serialize device_serial JSON");
        return ESP_FAIL;
    }

    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) {
        ESP_LOGE(TAG, "Failed to allocate memory for device_serial response");
        free(json_string);
        return ESP_ERR_NO_MEM;
    }
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    free(json_string);

    ESP_LOGI(TAG, "=== device_serial_handler SUCCESS: %s ===", serial_number);
    return ESP_OK;
}

esp_err_t ble_endpoint_wifi_connection_status(uint32_t session_id,
                                               const uint8_t *inbuf, ssize_t inlen,
                                               uint8_t **outbuf, ssize_t *outlen,
                                               void *priv_data)
{
    bool connected = wifi_is_connected();
    bool failed    = wifi_is_credential_failed();
    ESP_LOGI(TAG, "=== wifi_connection_status: connected=%s, failed=%s ===",
             connected ? "true" : "false", failed ? "true" : "false");

    cJSON *response = cJSON_CreateObject();
    if (!response) return ESP_FAIL;
    cJSON_AddBoolToObject(response, "connected", connected);
    cJSON_AddBoolToObject(response, "failed", failed);

    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    if (!json_string) return ESP_FAIL;

    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) { free(json_string); return ESP_ERR_NO_MEM; }
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    free(json_string);
    return ESP_OK;
}

esp_err_t ble_endpoint_device_claim_token_set(uint32_t session_id,
                                               const uint8_t *inbuf, ssize_t inlen,
                                               uint8_t **outbuf, ssize_t *outlen,
                                               void *priv_data)
{
    ESP_LOGI(TAG, "=== device_claim_token_set_handler CALLED ===");
    ESP_LOGI(TAG, "Session ID: %lu, Input length: %zd", session_id, inlen);

    if (!inbuf || inlen <= 0) {
        ESP_LOGE(TAG, "Invalid input buffer for claim token");
        return ESP_FAIL;
    }

    char json_buffer[512];
    if (inlen >= (ssize_t)sizeof(json_buffer)) {
        ESP_LOGE(TAG, "Input buffer too large: %zd", inlen);
        return ESP_FAIL;
    }
    memcpy(json_buffer, inbuf, inlen);
    json_buffer[inlen] = '\0';
    ESP_LOGI(TAG, "Received JSON: %s", json_buffer);

    cJSON *received = cJSON_Parse(json_buffer);
    if (!received) {
        ESP_LOGE(TAG, "Failed to parse claim token JSON");
        return ESP_FAIL;
    }

    cJSON *claim_id_item = cJSON_GetObjectItem(received, "claimId");
    if (!claim_id_item || !claim_id_item->valuestring) {
        ESP_LOGE(TAG, "Missing claimId in request");
        cJSON_Delete(received);
        return ESP_FAIL;
    }

    cJSON *claim_token_item = cJSON_GetObjectItem(received, "claimToken");
    if (!claim_token_item || !claim_token_item->valuestring) {
        ESP_LOGE(TAG, "Missing claimToken in request");
        cJSON_Delete(received);
        return ESP_FAIL;
    }

    strncpy(s_claim_id, claim_id_item->valuestring, sizeof(s_claim_id) - 1);
    strncpy(s_claim_token, claim_token_item->valuestring, sizeof(s_claim_token) - 1);
    s_claim_credentials_received = true;

    ESP_LOGI(TAG, "=== CLAIM CREDENTIALS RECEIVED ===");
    ESP_LOGI(TAG, "claimId:    %s", s_claim_id);
    ESP_LOGI(TAG, "claimToken: %s", s_claim_token);
    ESP_LOGI(TAG, "==============================");
    cJSON_Delete(received);

    cJSON *response = cJSON_CreateObject();
    if (!response) {
        ESP_LOGE(TAG, "Failed to create JSON response for claim token");
        return ESP_FAIL;
    }
    cJSON_AddBoolToObject(response, "received", true);

    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    if (!json_string) {
        ESP_LOGE(TAG, "Failed to serialize claim token response JSON");
        return ESP_FAIL;
    }

    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) {
        ESP_LOGE(TAG, "Failed to allocate memory for claim token response");
        free(json_string);
        return ESP_ERR_NO_MEM;
    }
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    free(json_string);

    ESP_LOGI(TAG, "=== device_claim_token_set_handler SUCCESS ===");
    return ESP_OK;
}

esp_err_t ble_endpoint_fleet_provisioning_status(uint32_t session_id,
                                                   const uint8_t *inbuf, ssize_t inlen,
                                                   uint8_t **outbuf, ssize_t *outlen,
                                                   void *priv_data)
{
    const char* status_str;
    switch (s_fleet_prov_status) {
        case FLEET_PROV_STATUS_PENDING: status_str = "pending"; break;
        case FLEET_PROV_STATUS_SUCCESS: status_str = "success"; break;
        case FLEET_PROV_STATUS_FAILED:  status_str = "failed";  break;
        default:                        status_str = "idle";    break;
    }
    ESP_LOGI(TAG, "=== fleet_provisioning_status: %s ===", status_str);

    cJSON *response = cJSON_CreateObject();
    if (!response) return ESP_FAIL;
    cJSON_AddStringToObject(response, "status", status_str);

    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    if (!json_string) return ESP_FAIL;

    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) { free(json_string); return ESP_ERR_NO_MEM; }
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    free(json_string);
    return ESP_OK;
}

// --- Public API ---

bool wifi_claim_credentials_received(void) {
    return s_claim_credentials_received;
}

void wifi_get_claim_credentials(char *claim_id_out, size_t claim_id_len,
                                 char *claim_token_out, size_t claim_token_len) {
    if (claim_id_out && claim_id_len > 0) {
        strncpy(claim_id_out, s_claim_id, claim_id_len - 1);
        claim_id_out[claim_id_len - 1] = '\0';
    }
    if (claim_token_out && claim_token_len > 0) {
        strncpy(claim_token_out, s_claim_token, claim_token_len - 1);
        claim_token_out[claim_token_len - 1] = '\0';
    }
}

void wifi_reset_claim_credentials(void) {
    memset(s_claim_id, 0, sizeof(s_claim_id));
    memset(s_claim_token, 0, sizeof(s_claim_token));
    s_claim_credentials_received = false;
    ESP_LOGI(TAG, "Claim credentials reset");
}

fleet_prov_status_t wifi_get_fleet_provisioning_status(void) {
    return s_fleet_prov_status;
}

void wifi_set_fleet_provisioning_status(fleet_prov_status_t status) {
    s_fleet_prov_status = status;
    const char* str;
    switch (status) {
        case FLEET_PROV_STATUS_PENDING: str = "PENDING"; break;
        case FLEET_PROV_STATUS_SUCCESS: str = "SUCCESS"; break;
        case FLEET_PROV_STATUS_FAILED:  str = "FAILED";  break;
        default:                        str = "IDLE";    break;
    }
    ESP_LOGI(TAG, "Fleet provisioning status: %s", str);
}

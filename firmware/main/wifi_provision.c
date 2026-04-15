#include "wifi_provision.h"
#include "sdkconfig.h"

#if !CONFIG_EMULATOR_MODE

#include <esp_wifi.h>
#include <esp_event.h>
#include <esp_err.h>
#include <esp_log.h>
#include <esp_mac.h>
#include <stdlib.h>
#include <wifi_provisioning/manager.h>
#include <wifi_provisioning/scheme_ble.h>
#include <string.h>
#include <cJSON.h>
#include "device_config.h"
#include "supervisor.h"
#include "claim.h"

#define TAG "WifiProv"


bool wifiprov_is_provisioned()
{
    bool provisioned = false;
    ESP_ERROR_CHECK(wifi_prov_mgr_is_provisioned(&provisioned));
    return provisioned;
}

void wifiprov_reset_provision()
{
    ESP_ERROR_CHECK(wifi_prov_mgr_reset_provisioning());
}

void wifiprov_deinit()
{
    wifi_prov_mgr_deinit();
}

static void wifiprov_event_handler(void *user_data, wifi_prov_cb_event_t event, void *event_data)
{
    switch (event) {
        case WIFI_PROV_CRED_RECV:
            ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_CRED_RECV - WiFi credentials received from app");
            break;
        case WIFI_PROV_CRED_SUCCESS:
            ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_CRED_SUCCESS - Device successfully connected to WiFi");
            break;
        case WIFI_PROV_CRED_FAIL:
            ESP_LOGE(TAG, "WIFI_PROV_CRED_FAIL - Failed to connect to WiFi (bad SSID/password or network unavailable)");
            wifi_prov_mgr_reset_sm_state_on_failure();
            ESP_ERROR_CHECK(supervisor_submit_event(EVENT_PROVISION_FAILED));
            break;
        case WIFI_PROV_START:
            ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_START");
            ESP_ERROR_CHECK(supervisor_submit_event(EVENT_PROVISION_STARTED));
            break;
        case WIFI_PROV_END:
            ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_END");
            // WiFi provisioning only ends on success
            ESP_ERROR_CHECK(supervisor_submit_event(EVENT_PROVISION_WIFI_SUCCESS));
            break;
        case WIFI_PROV_DEINIT:
            ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_DEINIT");
            break;
        default:
            break;
    }
}

static esp_err_t ble_endpoint_device_claim_token_set(uint32_t session_id,
                                               const uint8_t *inbuf, ssize_t inlen,
                                               uint8_t **outbuf, ssize_t *outlen,
                                               void *priv_data)
{
    ESP_LOGI(TAG, "=== device_claim_token_set_handler CALLED ===");
    ESP_LOGI(TAG, "Session ID: %lu, Input length: %zd", session_id, inlen);


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

    ESP_LOGI(TAG, "=== CLAIM CREDENTIALS RECEIVED ===");
    ESP_LOGI(TAG, "claimId:    %s", claim_id_item->valuestring);
    ESP_LOGI(TAG, "claimToken: %s", claim_token_item->valuestring);
    ESP_LOGI(TAG, "==============================");

    // Store the claim credentials so they can be fetched later by the supervisor
    claim_set_credentials(claim_id_item->valuestring, claim_token_item->valuestring);
    ESP_ERROR_CHECK(supervisor_submit_event(EVENT_CLAIM_CREDENTIALS_RECEIVED));

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

    return ESP_OK;
}

esp_err_t ble_endpoint_device_serial(uint32_t session_id,
                                      const uint8_t *inbuf, ssize_t inlen,
                                      uint8_t **outbuf, ssize_t *outlen,
                                      void *priv_data)
{
    ESP_LOGI(TAG, "=== device_serial_handler CALLED ===");
    ESP_LOGI(TAG, "Session ID: %lu, Input length: %zd", session_id, inlen);

    char sn[SERIAL_NUMBER_STR_SIZE];
    devcfg_get_serial_number_str(sn, sizeof(sn));

    cJSON *response = cJSON_CreateObject();
    if (!response) {
        ESP_LOGE(TAG, "Failed to create JSON response for device_serial");
        return ESP_FAIL;
    }
    cJSON_AddStringToObject(response, "serialNumber", sn);

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

    ESP_LOGI(TAG, "=== device_serial_handler SUCCESS: %s ===", sn);
    return ESP_OK;
}

void wifiprov_start_provision()
{
    wifi_prov_mgr_config_t prov_config = {
        .scheme = wifi_prov_scheme_ble,
        .scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM,
        .app_event_handler = {
            .event_cb = wifiprov_event_handler,
            .user_data = NULL
        },
    };
    ESP_ERROR_CHECK(wifi_prov_mgr_init(prov_config));
        
    // Create custom endpoints for device serial number (must be created before start_provisioning)
    ESP_LOGI(TAG, "Creating device_serial endpoint...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("device_serial"));
    ESP_LOGI(TAG, "device_serial endpoint created successfully");
        
    ESP_LOGI(TAG, "Creating device_claim_token_set endpoint...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("device_claim_token_set"));
    ESP_LOGI(TAG, "device_claim_token_set endpoint created successfully");
            
    char sn[SERIAL_NUMBER_STR_SIZE];
    devcfg_get_serial_number_str(sn, sizeof(sn));

    // Build BLE device name from serial number
    char service_name[24];
    snprintf(service_name, sizeof(service_name), "cabiNET-%s", sn);

    ESP_LOGI(TAG, "Starting BLE provisioning as: %s", service_name);

    // Security 1 with no proof-of-possession (NULL)
    ESP_ERROR_CHECK(wifi_prov_mgr_start_provisioning(WIFI_PROV_SECURITY_0, NULL, service_name, NULL));
    
    // Register handlers for custom endpoints (must be registered after start_provisioning)
    ESP_LOGI(TAG, "Registering device_serial endpoint handler...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register("device_serial", ble_endpoint_device_serial, NULL));
    ESP_LOGI(TAG, "device_serial endpoint handler registered successfully");
        
    ESP_LOGI(TAG, "Registering device_claim_token_set endpoint handler...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register("device_claim_token_set", ble_endpoint_device_claim_token_set,      NULL));
    ESP_LOGI(TAG, "device_claim_token_set endpoint handler registered successfully"); 
}

#else /* CONFIG_EMULATOR_MODE — stubs so the linker is happy */

bool wifiprov_is_provisioned(void) { return false; }
void wifiprov_start_provision(void) { }
void wifiprov_reset_provision(void) { }
void wifiprov_deinit(void) { }

#endif /* !CONFIG_EMULATOR_MODE */

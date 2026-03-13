#include "device_provisioning.h"
#include "mqtt_handler.h"
#include "sdkconfig.h"
#include "network.h"
#include "wifi.h"
#include "esp_log.h"
#include "esp_wifi.h"
#include "cJSON.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "fleet_provisioning.h"  // AWS IoT Fleet Provisioning library
#include <string.h>
#include <nvs.h>
#include <time.h>

#define TAG "DeviceProvisioning"
#define TEMPLATE_NAME "TenantDeviceProvisioningTemplate"
#define TEMPLATE_NAME_LENGTH (sizeof(TEMPLATE_NAME) - 1)

// Event bits for async responses
#define CREATE_KEYS_ACCEPTED_BIT    (1 << 0)
#define CREATE_KEYS_REJECTED_BIT    (1 << 1)
#define REGISTER_THING_ACCEPTED_BIT (1 << 2)
#define REGISTER_THING_REJECTED_BIT (1 << 3)

// Response storage
static char* permanent_cert_pem = NULL;
static char* permanent_key_pem = NULL;
static char* certificate_ownership_token = NULL;
static char* thing_name_response = NULL;
static EventGroupHandle_t provisioning_event_group = NULL;

// Claim credentials (provided by app via BLE)
static char* claim_id_stored = NULL;
static char* claim_token = NULL;

// MQTT callback for CreateKeys accepted
static void on_create_keys_accepted(const char* topic, const char* payload, size_t len) {
    ESP_LOGI(TAG, "CreateKeysAndCertificate ACCEPTED");
    ESP_LOGD(TAG, "Response: %.*s", len, payload);
    
    // Parse JSON response
    cJSON *json = cJSON_ParseWithLength(payload, len);
    if (json == NULL) {
        ESP_LOGE(TAG, "Failed to parse CreateKeys response");
        xEventGroupSetBits(provisioning_event_group, CREATE_KEYS_REJECTED_BIT);
        return;
    }
    
    // Use AWS Fleet Provisioning library constants for JSON keys
    cJSON *cert_pem = cJSON_GetObjectItem(json, FP_API_CERTIFICATE_PEM_KEY);
    if (cJSON_IsString(cert_pem)) {
        permanent_cert_pem = strdup(cert_pem->valuestring);
        ESP_LOGI(TAG, "Permanent certificate received (%d bytes)", strlen(permanent_cert_pem));
    }
    
    cJSON *priv_key = cJSON_GetObjectItem(json, FP_API_PRIVATE_KEY_KEY);
    if (cJSON_IsString(priv_key)) {
        permanent_key_pem = strdup(priv_key->valuestring);
        ESP_LOGI(TAG, "Permanent private key received (%d bytes)", strlen(permanent_key_pem));
    }
    
    cJSON *token = cJSON_GetObjectItem(json, FP_API_OWNERSHIP_TOKEN_KEY);
    if (cJSON_IsString(token)) {
        certificate_ownership_token = strdup(token->valuestring);
        ESP_LOGD(TAG, "Ownership token received");
    }
    
    cJSON_Delete(json);
    
    if (permanent_cert_pem && permanent_key_pem && certificate_ownership_token) {
        xEventGroupSetBits(provisioning_event_group, CREATE_KEYS_ACCEPTED_BIT);
    } else {
        ESP_LOGE(TAG, "Missing fields in CreateKeys response");
        xEventGroupSetBits(provisioning_event_group, CREATE_KEYS_REJECTED_BIT);
    }
}

// MQTT callback for CreateKeys rejected
static void on_create_keys_rejected(const char* topic, const char* payload, size_t len) {
    ESP_LOGE(TAG, "CreateKeysAndCertificate REJECTED");
    ESP_LOGE(TAG, "Response: %.*s", len, payload);
    xEventGroupSetBits(provisioning_event_group, CREATE_KEYS_REJECTED_BIT);
}

// MQTT callback for RegisterThing accepted
static void on_register_thing_accepted(const char* topic, const char* payload, size_t len) {
    ESP_LOGI(TAG, "RegisterThing ACCEPTED");
    ESP_LOGD(TAG, "Response: %.*s", len, payload);
    
    // Parse JSON response
    cJSON *json = cJSON_ParseWithLength(payload, len);
    if (json == NULL) {
        ESP_LOGE(TAG, "Failed to parse RegisterThing response");
        xEventGroupSetBits(provisioning_event_group, REGISTER_THING_REJECTED_BIT);
        return;
    }
    
    // Use AWS Fleet Provisioning library constant for thingName key
    cJSON *thing_name = cJSON_GetObjectItem(json, FP_API_THING_NAME_KEY);
    if (cJSON_IsString(thing_name)) {
        thing_name_response = strdup(thing_name->valuestring);
        ESP_LOGI(TAG, "Thing registered: %s", thing_name_response);
    }
    
    cJSON_Delete(json);
    
    if (thing_name_response) {
        xEventGroupSetBits(provisioning_event_group, REGISTER_THING_ACCEPTED_BIT);
    } else {
        ESP_LOGE(TAG, "Missing thingName in RegisterThing response");
        xEventGroupSetBits(provisioning_event_group, REGISTER_THING_REJECTED_BIT);
    }
}

// MQTT callback for RegisterThing rejected
static void on_register_thing_rejected(const char* topic, const char* payload, size_t len) {
    ESP_LOGE(TAG, "RegisterThing REJECTED");
    ESP_LOGE(TAG, "Response: %.*s", len, payload);
    xEventGroupSetBits(provisioning_event_group, REGISTER_THING_REJECTED_BIT);
}

bool device_provisioning_is_provisioned(void) {
    // Check all three credentials (cert, key, thing name)
    char* device_cert = NULL;
    char* device_key = NULL;
    char thing_name[128];
    size_t len = 0;

    esp_err_t cert_err = network_load_cert_from_nvs("DEVICE_CERT", &device_cert, &len);
    if (device_cert != NULL) { free(device_cert); }

    esp_err_t key_err = network_load_cert_from_nvs("DEVICE_KEY", &device_key, &len);
    if (device_key != NULL) { free(device_key); }

    esp_err_t name_err = network_load_thing_name(thing_name, sizeof(thing_name));

    return (cert_err == ESP_OK && key_err == ESP_OK && name_err == ESP_OK);
}

void device_provisioning_clear(void) {
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to open NVS for clearing provisioning: %d", err);
        return;
    }
    nvs_erase_key(h, "DEVICE_CERT");
    nvs_erase_key(h, "DEVICE_KEY");
    nvs_erase_key(h, "THING_NAME");
    nvs_erase_key(h, "PROV_SUCCESS");
    nvs_commit(h);
    nvs_close(h);
    ESP_LOGI(TAG, "Provisioning credentials cleared from NVS");
    
    // Also clear WiFi provisioning credentials so device re-provisions from scratch
    esp_wifi_restore();
    ESP_LOGI(TAG, "WiFi credentials cleared");
}

void device_provisioning_mark_success(void) {
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to open NVS for marking success: %d", err);
        return;
    }
    uint8_t flag = 1;
    err = nvs_set_u8(h, "PROV_SUCCESS", flag);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to write PROV_SUCCESS flag: %d", err);
    }
    nvs_commit(h);
    nvs_close(h);
    ESP_LOGI(TAG, "✓ Provisioning marked as complete in NVS");
}

bool device_provisioning_is_complete(void) {
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READONLY, &h);
    if (err != ESP_OK) {
        return false;
    }
    uint8_t flag = 0;
    err = nvs_get_u8(h, "PROV_SUCCESS", &flag);
    nvs_close(h);
    return (err == ESP_OK && flag == 1);
}

void mqtt_record_auth_failure_start(void) {
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to open NVS for MQTT failure tracking: %d", err);
        return;
    }
    
    // Only record if not already set (don't overwrite on subsequent failures)
    uint64_t existing_timestamp = 0;
    err = nvs_get_u64(h, "MQTT_AUTH_FAIL_START", &existing_timestamp);
    if (err == ESP_OK) {
        // Already recorded, don't overwrite
        nvs_close(h);
        return;
    }
    
    // Record current time as failure start
    time_t current_time = time(NULL);
    err = nvs_set_u64(h, "MQTT_AUTH_FAIL_START", (uint64_t)current_time);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to write MQTT auth failure timestamp: %d", err);
    } else {
        ESP_LOGW(TAG, "MQTT auth failure recorded - 48h timeout started");
    }
    nvs_commit(h);
    nvs_close(h);
}

bool mqtt_check_auth_failure_timeout(uint32_t hours) {
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READONLY, &h);
    if (err != ESP_OK) {
        return false;
    }
    
    uint64_t failure_start_time = 0;
    err = nvs_get_u64(h, "MQTT_AUTH_FAIL_START", &failure_start_time);
    nvs_close(h);
    
    if (err != ESP_OK) {
        // No failure record, so no timeout
        return false;
    }
    
    time_t current_time = time(NULL);
    uint64_t elapsed_seconds = (uint64_t)current_time - failure_start_time;
    uint64_t timeout_seconds = (uint64_t)hours * 3600;
    
    return (elapsed_seconds >= timeout_seconds);
}

void mqtt_clear_auth_failure_record(void) {
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to open NVS for clearing MQTT failure record: %d", err);
        return;
    }
    
    nvs_erase_key(h, "MQTT_AUTH_FAIL_START");
    nvs_commit(h);
    nvs_close(h);
    ESP_LOGI(TAG, "✓ MQTT auth failure record cleared");
}

esp_err_t device_provisioning_start(const char* claim_cert_pem, const char* claim_key_pem,
                                     const char* claim_id_param, const char* claim_token_param) {
    esp_err_t ret = ESP_FAIL;
    char* claim_cert = NULL;
    char* claim_key = NULL;
    char serial_number[32];
    char client_id[128];
    char* root_ca = NULL;
    size_t root_ca_len = 0;
    
    ESP_LOGI(TAG, "===== Starting AWS IoT Fleet Provisioning =====");
    
    // Phase 1: Check if already provisioned
    if (device_provisioning_is_provisioned()) {
        ESP_LOGW(TAG, "Device is already provisioned");
        return ESP_ERR_INVALID_STATE;
    }
    
    // Create event group
    provisioning_event_group = xEventGroupCreate();
    if (provisioning_event_group == NULL) {
        ESP_LOGE(TAG, "Failed to create event group");
        return ESP_ERR_NO_MEM;
    }
    
    // Phase 2: Get serial number (MAC address)
    uint8_t mac[6];
    size_t mac_len;
    network_get_serial_number(mac, &mac_len);
    snprintf(serial_number, sizeof(serial_number), "ESP32-%02X%02X%02X%02X%02X%02X",
             mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    ESP_LOGI(TAG, "Device Serial Number: %s", serial_number);
    
    // Phase 3: Use provided temp certs (RAM only - never written to NVS)
    ESP_LOGI(TAG, "Phase 1: Using provided temp cert credentials (RAM only)...");
    claim_cert = strdup(claim_cert_pem);
    claim_key  = strdup(claim_key_pem);
    if (!claim_cert || !claim_key) {
        ESP_LOGE(TAG, "Failed to duplicate temp cert credentials");
        ret = ESP_ERR_NO_MEM;
        goto cleanup;
    }

    claim_id_stored = strdup(claim_id_param);  // Provided by app via BLE endpoint
    claim_token = strdup(claim_token_param);   // Provided by app via BLE endpoint

    ESP_LOGI(TAG, "✅ Temp cert credentials ready");

    // Client ID for provisioning = serial number only
    snprintf(client_id, sizeof(client_id), "%s", serial_number);
    
    // Phase 4: Load root CA
    extern const uint8_t aws_root_ca_start[] asm("_binary_root_ca_pem_start");
    extern const uint8_t aws_root_ca_end[] asm("_binary_root_ca_pem_end");
    root_ca_len = aws_root_ca_end - aws_root_ca_start;
    root_ca = (char*)malloc(root_ca_len + 1);
    if (root_ca == NULL) {
        ESP_LOGE(TAG, "Failed to allocate root CA");
        ret = ESP_ERR_NO_MEM;
        goto cleanup;
    }
    memcpy(root_ca, aws_root_ca_start, root_ca_len);
    root_ca[root_ca_len] = '\0';
    
    // Phase 5: Connect to AWS IoT with claim credentials
    ESP_LOGI(TAG, "Phase 2: Connecting to AWS IoT with claim certificate...");
    ret = mqtt_connect_with_certs(client_id, root_ca, claim_cert, claim_key);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to connect with claim credentials");
        goto cleanup;
    }
    
    // Wait for connection
    vTaskDelay(pdMS_TO_TICKS(1000));
    
    if (!mqtt_is_connected()) {
        ESP_LOGE(TAG, "MQTT not connected after claim cert connection");
        ret = ESP_FAIL;
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "✅ Connected to AWS IoT with claim certificate");
    
    // Phase 6: Subscribe to CreateKeysAndCertificate topics using AWS library macros
    ESP_LOGI(TAG, "Phase 3: Requesting permanent credentials...");
    
    // Use AWS Fleet Provisioning library topic macros
    ret = mqtt_subscribe(FP_JSON_CREATE_KEYS_ACCEPTED_TOPIC, on_create_keys_accepted);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe to create/accepted");
        goto cleanup;
    }
    
    ret = mqtt_subscribe(FP_JSON_CREATE_KEYS_REJECTED_TOPIC, on_create_keys_rejected);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe to create/rejected");
        goto cleanup;
    }
    
    vTaskDelay(pdMS_TO_TICKS(500));
    
    // Phase 7: Publish CreateKeysAndCertificate request
    const char* create_keys_payload = "{}";
    ret = mqtt_publish(FP_JSON_CREATE_KEYS_PUBLISH_TOPIC, create_keys_payload, strlen(create_keys_payload));
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to publish CreateKeys request");
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "Waiting for CreateKeysAndCertificate response...");
    
    // Wait for response (60 second timeout)
    EventBits_t bits = xEventGroupWaitBits(provisioning_event_group,
                                           CREATE_KEYS_ACCEPTED_BIT | CREATE_KEYS_REJECTED_BIT,
                                           pdTRUE, pdFALSE, pdMS_TO_TICKS(60000));
    
    if (bits & CREATE_KEYS_REJECTED_BIT) {
        ESP_LOGE(TAG, "CreateKeysAndCertificate was rejected");
        ret = ESP_FAIL;
        goto cleanup;
    }
    
    if (!(bits & CREATE_KEYS_ACCEPTED_BIT)) {
        ESP_LOGE(TAG, "Timeout waiting for CreateKeysAndCertificate response");
        ret = ESP_ERR_TIMEOUT;
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "✅ Permanent credentials received");
    
    // Phase 8: Save permanent credentials to NVS
    ESP_LOGI(TAG, "Saving permanent credentials to NVS...");
    ret = network_save_cert_to_nvs("DEVICE_CERT", permanent_cert_pem);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to save device certificate");
        goto cleanup;
    }
    
    ret = network_save_cert_to_nvs("DEVICE_KEY", permanent_key_pem);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to save device key");
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "✅ Permanent credentials saved to NVS");
    
    // Phase 9: Subscribe to RegisterThing topics using AWS library helper function
    ESP_LOGI(TAG, "Phase 4: Registering Thing with provisioning template...");
    
    char register_accepted_topic[256];
    char register_rejected_topic[256];
    uint16_t topic_len = 0;
    
    // Use AWS Fleet Provisioning library function to build RegisterThing topics
    FleetProvisioningStatus_t fp_status;
    
    fp_status = FleetProvisioning_GetRegisterThingTopic(
        register_accepted_topic, 
        sizeof(register_accepted_topic),
        FleetProvisioningJson,
        FleetProvisioningAccepted,
        TEMPLATE_NAME,
        TEMPLATE_NAME_LENGTH,
        &topic_len);
    
    if (fp_status != FleetProvisioningSuccess) {
        ESP_LOGE(TAG, "Failed to build RegisterThing accepted topic");
        ret = ESP_FAIL;
        goto cleanup;
    }
    register_accepted_topic[topic_len] = '\0';
    
    fp_status = FleetProvisioning_GetRegisterThingTopic(
        register_rejected_topic,
        sizeof(register_rejected_topic),
        FleetProvisioningJson,
        FleetProvisioningRejected,
        TEMPLATE_NAME,
        TEMPLATE_NAME_LENGTH,
        &topic_len);
    
    if (fp_status != FleetProvisioningSuccess) {
        ESP_LOGE(TAG, "Failed to build RegisterThing rejected topic");
        ret = ESP_FAIL;
        goto cleanup;
    }
    register_rejected_topic[topic_len] = '\0';
    
    ret = mqtt_subscribe(register_accepted_topic, on_register_thing_accepted);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe to RegisterThing accepted");
        goto cleanup;
    }
    
    ret = mqtt_subscribe(register_rejected_topic, on_register_thing_rejected);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to subscribe to RegisterThing rejected");
        goto cleanup;
    }
    
    vTaskDelay(pdMS_TO_TICKS(500));
    
    // Phase 10: Build and publish RegisterThing request
    cJSON *register_request = cJSON_CreateObject();
    
    // Use AWS Fleet Provisioning library constant for ownership token key
    cJSON_AddStringToObject(register_request, FP_API_OWNERSHIP_TOKEN_KEY, certificate_ownership_token);
    
    // Use AWS Fleet Provisioning library constant for parameters key
    cJSON *parameters = cJSON_CreateObject();
    cJSON_AddStringToObject(parameters, "SerialNumber", serial_number);
    cJSON_AddStringToObject(parameters, "ClaimId", claim_id_stored);
    cJSON_AddStringToObject(parameters, "ClaimToken", claim_token);
    ESP_LOGI(TAG, "RegisterThing parameters: SerialNumber=%s, ClaimId=%s", serial_number, claim_id_stored);
    cJSON_AddItemToObject(register_request, FP_API_PARAMETERS_KEY, parameters);
    
    char* register_payload = cJSON_PrintUnformatted(register_request);
    cJSON_Delete(register_request);
    
    if (register_payload == NULL) {
        ESP_LOGE(TAG, "Failed to build RegisterThing payload");
        ret = ESP_FAIL;
        goto cleanup;
    }
    
    ESP_LOGD(TAG, "RegisterThing payload: %s", register_payload);
    
    // Build publish topic using AWS library macro
    char register_publish_topic[256];
    fp_status = FleetProvisioning_GetRegisterThingTopic(
        register_publish_topic,
        sizeof(register_publish_topic),
        FleetProvisioningJson,
        FleetProvisioningPublish,
        TEMPLATE_NAME,
        TEMPLATE_NAME_LENGTH,
        &topic_len);
    
    if (fp_status != FleetProvisioningSuccess) {
        ESP_LOGE(TAG, "Failed to build RegisterThing publish topic");
        free(register_payload);
        ret = ESP_FAIL;
        goto cleanup;
    }
    register_publish_topic[topic_len] = '\0';
    
    ret = mqtt_publish(register_publish_topic, register_payload, strlen(register_payload));
    free(register_payload);
    
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to publish RegisterThing request");
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "Waiting for RegisterThing response...");
    
    // Wait for response (60 second timeout)
    bits = xEventGroupWaitBits(provisioning_event_group,
                               REGISTER_THING_ACCEPTED_BIT | REGISTER_THING_REJECTED_BIT,
                               pdTRUE, pdFALSE, pdMS_TO_TICKS(60000));
    
    if (bits & REGISTER_THING_REJECTED_BIT) {
        ESP_LOGE(TAG, "RegisterThing was rejected");
        ret = ESP_FAIL;
        goto cleanup;
    }
    
    if (!(bits & REGISTER_THING_ACCEPTED_BIT)) {
        ESP_LOGE(TAG, "Timeout waiting for RegisterThing response");
        ret = ESP_ERR_TIMEOUT;
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "✅ Thing registered successfully: %s", thing_name_response);
    
    // Phase 11: Save Thing name to NVS
    ret = network_save_thing_name(thing_name_response);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to save Thing name");
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "✅ Thing name saved to NVS");
    
    // Phase 12: Disconnect and reconnect with permanent credentials
    ESP_LOGI(TAG, "Phase 5: Reconnecting with permanent credentials...");
    
    mqtt_disconnect();
    vTaskDelay(pdMS_TO_TICKS(1000));
    
    ret = mqtt_connect_with_certs(thing_name_response, root_ca, permanent_cert_pem, permanent_key_pem);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to reconnect with permanent credentials");
        goto cleanup;
    }
    
    vTaskDelay(pdMS_TO_TICKS(1000));
    
    if (!mqtt_is_connected()) {
        ESP_LOGE(TAG, "MQTT not connected after permanent cert connection");
        ret = ESP_FAIL;
        goto cleanup;
    }
    
    ESP_LOGI(TAG, "✅ Reconnected with permanent credentials as %s", thing_name_response);
    ESP_LOGI(TAG, "===== Fleet Provisioning Complete! =====");
    
    ret = ESP_OK;
    
cleanup:
    // Free allocated memory
    if (claim_cert) free(claim_cert);
    if (claim_key) free(claim_key);
    if (claim_token) free(claim_token);
    if (root_ca) free(root_ca);
    if (permanent_cert_pem) free(permanent_cert_pem);
    if (permanent_key_pem) free(permanent_key_pem);
    if (certificate_ownership_token) free(certificate_ownership_token);
    if (thing_name_response) free(thing_name_response);
    
    // Reset globals
    permanent_cert_pem = NULL;
    permanent_key_pem = NULL;
    certificate_ownership_token = NULL;
    thing_name_response = NULL;
    claim_token = NULL;
    
    if (provisioning_event_group) {
        vEventGroupDelete(provisioning_event_group);
        provisioning_event_group = NULL;
    }
    
    return ret;
}

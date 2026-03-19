#include "fleet_provision.h"
#include "mqtt_wrapper.h"
#include "sdkconfig.h"
#include "network.h"
#include "wifi.h"
#include "esp_log.h"
#include "esp_wifi.h"
#include "cJSON.h"
#include "freertos/FreeRTOS.h"
#include "freertos/timers.h"
#include "fleet_provisioning.h"
#include "mqtt_client.h"
#include <string.h>
#include <nvs.h>
#include "supervisor.h"
#include "device_config.h"

#define TAG "DeviceProvisioning"
#define TEMPLATE_NAME "TenantDeviceProvisioningTemplate"
#define TEMPLATE_NAME_LENGTH (sizeof(TEMPLATE_NAME) - 1)

// Overall timeout for the entire async provisioning process (60s)
#define PROV_OVERALL_TIMEOUT_MS 60000 

// Provisioning State Machine
typedef enum {
    PROV_STATE_IDLE = 0,
    PROV_STATE_CONNECTING,
    PROV_STATE_SUB_CREATE_KEYS,
    PROV_STATE_PUB_CREATE_KEYS,
    PROV_STATE_SUB_REGISTER_THING,
    PROV_STATE_PUB_REGISTER_THING,
    PROV_STATE_DONE
} prov_state_t;

// Encapsulated Provisioning Context
typedef struct {
    prov_state_t state;
    TimerHandle_t timeout_timer;
    uint8_t sub_ack_count; // Tracks how many SUBACKs we've received for the current phase
    
    char* perm_cert_pem;
    char* perm_key_pem;
    char* ownership_token;
    char* thing_name;
    char* claim_id;
    char* claim_token;
    
    char reg_acc_topic[256];
    char reg_rej_topic[256];
    char pub_topic[256];
    char serial_number[SERIAL_NUMBER_STR_SIZE];
} provisioning_ctx_t;

static provisioning_ctx_t* s_ctx = NULL;

/* --- Helpers --- */

static bool is_topic_match(const char* event_topic, int event_topic_len, const char* target_topic) {
    if (!event_topic || !target_topic) return false;
    int target_len = strlen(target_topic);
    return (event_topic_len == target_len && strncmp(event_topic, target_topic, target_len) == 0);
}

void fleet_provision_deinit() {
    if (!s_ctx) return;
    
    
    if (s_ctx->timeout_timer) {
        xTimerStop(s_ctx->timeout_timer, 0);
        xTimerDelete(s_ctx->timeout_timer, 0);
    }
    
    if (s_ctx->perm_cert_pem) free(s_ctx->perm_cert_pem);
    if (s_ctx->perm_key_pem) free(s_ctx->perm_key_pem);
    if (s_ctx->ownership_token) free(s_ctx->ownership_token);
    if (s_ctx->thing_name) free(s_ctx->thing_name);
    if (s_ctx->claim_id) free(s_ctx->claim_id);
    if (s_ctx->claim_token) free(s_ctx->claim_token);
    
    free(s_ctx);
    s_ctx = NULL;
    
    // Disconnect the claim session. We don't need it anymore regardless of success/fail.
    mqtt_wrapper_disconnect();    

    supervisor_submit_event(EVENT_FLEET_PROVISION_DEINIT);
}

static void notify_finish(esp_err_t final_result) {
    ESP_LOGI(TAG, "Result: %d", final_result);
    supervisor_submit_event(final_result == ESP_OK ? EVENT_FLEET_PROVISION_SUCCESS : EVENT_FLEET_PROVISION_FAILED);
}

// Global timeout callback
static void provisioning_timeout_cb(TimerHandle_t xTimer) {
    ESP_LOGE(TAG, "Provisioning timed out!");
    notify_finish(ESP_ERR_TIMEOUT);
}

/* --- MQTT Data Handlers (Phase Logic) --- */

static void handle_create_keys_response(const char* payload, size_t len, bool is_accepted) {
    if (!is_accepted) {
        ESP_LOGE(TAG, "CreateKeys REJECTED: %.*s", len, payload);
        notify_finish(ESP_FAIL);
        return;
    }

    cJSON *json = cJSON_ParseWithLength(payload, len);
    if (!json) {
        ESP_LOGE(TAG, "Failed to parse CreateKeys response");
        notify_finish(ESP_FAIL);
        return;
    }
    
    cJSON *cert_pem = cJSON_GetObjectItem(json, FP_API_CERTIFICATE_PEM_KEY);
    cJSON *priv_key = cJSON_GetObjectItem(json, FP_API_PRIVATE_KEY_KEY);
    cJSON *token = cJSON_GetObjectItem(json, FP_API_OWNERSHIP_TOKEN_KEY);
    
    if (cJSON_IsString(cert_pem) && cJSON_IsString(priv_key) && cJSON_IsString(token)) {
        s_ctx->perm_cert_pem = strdup(cert_pem->valuestring);
        s_ctx->perm_key_pem = strdup(priv_key->valuestring);
        s_ctx->ownership_token = strdup(token->valuestring);
        
        ESP_LOGI(TAG, "CreateKeys Success. Proceeding to Phase 2: RegisterThing");
        
        // Save to NVS immediately so we don't lose them
        ESP_ERROR_CHECK(devcfg_set_permanent_cert(s_ctx->perm_cert_pem, s_ctx->perm_key_pem));
        
        // Advance state and queue subscriptions for RegisterThing
        s_ctx->state = PROV_STATE_SUB_REGISTER_THING;
        s_ctx->sub_ack_count = 0;
        
        uint16_t topic_len = 0;
        FleetProvisioning_GetRegisterThingTopic(s_ctx->reg_acc_topic, sizeof(s_ctx->reg_acc_topic), FleetProvisioningJson, FleetProvisioningAccepted, TEMPLATE_NAME, TEMPLATE_NAME_LENGTH, &topic_len);
        s_ctx->reg_acc_topic[topic_len] = '\0';
        
        FleetProvisioning_GetRegisterThingTopic(s_ctx->reg_rej_topic, sizeof(s_ctx->reg_rej_topic), FleetProvisioningJson, FleetProvisioningRejected, TEMPLATE_NAME, TEMPLATE_NAME_LENGTH, &topic_len);
        s_ctx->reg_rej_topic[topic_len] = '\0';
        
        FleetProvisioning_GetRegisterThingTopic(s_ctx->pub_topic, sizeof(s_ctx->pub_topic), FleetProvisioningJson, FleetProvisioningPublish, TEMPLATE_NAME, TEMPLATE_NAME_LENGTH, &topic_len);
        s_ctx->pub_topic[topic_len] = '\0';

        mqtt_wrapper_subscribe(s_ctx->reg_acc_topic, 1);
        mqtt_wrapper_subscribe(s_ctx->reg_rej_topic, 1);
        
    } else {
        ESP_LOGE(TAG, "Missing required fields in CreateKeys response");
        notify_finish(ESP_FAIL);
    }
    
    cJSON_Delete(json);
}

static void handle_register_thing_response(const char* payload, size_t len, bool is_accepted) {
    if (!is_accepted) {
        ESP_LOGE(TAG, "RegisterThing REJECTED: %.*s", len, payload);
        notify_finish(ESP_FAIL);
        return;
    }

    cJSON *json = cJSON_ParseWithLength(payload, len);
    if (!json) {
        ESP_LOGE(TAG, "Failed to parse RegisterThing response");
        notify_finish(ESP_FAIL);
        return;
    }
    
    cJSON *thing_name = cJSON_GetObjectItem(json, FP_API_THING_NAME_KEY);
    if (cJSON_IsString(thing_name)) {
        s_ctx->thing_name = strdup(thing_name->valuestring);
        ESP_LOGI(TAG, "RegisterThing Success! Thing Name: %s", s_ctx->thing_name);
        
        // Save the final piece to NVS
        devcfg_set_thing_name(s_ctx->thing_name);
        
        // We are done!
        s_ctx->state = PROV_STATE_DONE;
        ESP_LOGI(TAG, "===== Fleet Provisioning Complete! =====");
        notify_finish(ESP_OK);
        
    } else {
        ESP_LOGE(TAG, "Missing thingName in RegisterThing response");
        notify_finish(ESP_FAIL);
    }
    
    cJSON_Delete(json);
}

/* --- Core Async State Machine --- */

static void provisioning_mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    if (!s_ctx) return; // Not provisioning
    
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;

    switch (event_id) {
        case MQTT_EVENT_CONNECTED:
            if (s_ctx->state == PROV_STATE_CONNECTING) {
                ESP_LOGI(TAG, "Connected. Phase 1: Requesting permanent credentials...");
                s_ctx->state = PROV_STATE_SUB_CREATE_KEYS;
                s_ctx->sub_ack_count = 0;
                
                esp_err_t err1 = mqtt_wrapper_subscribe(FP_JSON_CREATE_KEYS_ACCEPTED_TOPIC, 1);
                esp_err_t err2 = mqtt_wrapper_subscribe(FP_JSON_CREATE_KEYS_REJECTED_TOPIC, 1);
                
                if (err1 != ESP_OK || err2 != ESP_OK) {
                    ESP_LOGE(TAG, "CRITICAL: Failed to queue subscriptions! (err1:%d, err2:%d)", err1, err2);
                    notify_finish(ESP_FAIL);
                } else {
                    ESP_LOGI(TAG, "Subscriptions queued. Waiting for AWS broker ACK...");
                }
            }
            break;

        case MQTT_EVENT_SUBSCRIBED:
            s_ctx->sub_ack_count++;
            ESP_LOGI(TAG, "Received SUBACK (%d/2)", s_ctx->sub_ack_count);
            
            // Wait for both ACCEPTED and REJECTED subscriptions to be acknowledged
            if (s_ctx->sub_ack_count >= 2) {
                if (s_ctx->state == PROV_STATE_SUB_CREATE_KEYS) {
                    s_ctx->state = PROV_STATE_PUB_CREATE_KEYS;
                    ESP_LOGI(TAG, "All CreateKeys SUBACKs received. Publishing request...");
                    mqtt_wrapper_publish(FP_JSON_CREATE_KEYS_PUBLISH_TOPIC, "{}", 2, 1);
                }
                else if (s_ctx->state == PROV_STATE_SUB_REGISTER_THING) {
                    s_ctx->state = PROV_STATE_PUB_REGISTER_THING;
                    ESP_LOGD(TAG, "RegisterThing Subscriptions ACK'd. Publishing request.");
                    
                    cJSON *req = cJSON_CreateObject();
                    cJSON_AddStringToObject(req, FP_API_OWNERSHIP_TOKEN_KEY, s_ctx->ownership_token);
                    cJSON *params = cJSON_CreateObject();
                    cJSON_AddStringToObject(params, "SerialNumber", s_ctx->serial_number);
                    if (s_ctx->claim_id) cJSON_AddStringToObject(params, "ClaimId", s_ctx->claim_id);
                    if (s_ctx->claim_token) cJSON_AddStringToObject(params, "ClaimToken", s_ctx->claim_token);
                    cJSON_AddItemToObject(req, FP_API_PARAMETERS_KEY, params);
                    
                    char* payload = cJSON_PrintUnformatted(req);
                    cJSON_Delete(req);
                    
                    mqtt_wrapper_publish(s_ctx->pub_topic, payload, strlen(payload), 1);
                    free(payload);
                }
            }
            break;

        case MQTT_EVENT_DATA:
            if (s_ctx->state == PROV_STATE_PUB_CREATE_KEYS) {
                if (is_topic_match(event->topic, event->topic_len, FP_JSON_CREATE_KEYS_ACCEPTED_TOPIC)) {
                    handle_create_keys_response(event->data, event->data_len, true);
                } else if (is_topic_match(event->topic, event->topic_len, FP_JSON_CREATE_KEYS_REJECTED_TOPIC)) {
                    handle_create_keys_response(event->data, event->data_len, false);
                }
            } 
            else if (s_ctx->state == PROV_STATE_PUB_REGISTER_THING) {
                if (is_topic_match(event->topic, event->topic_len, s_ctx->reg_acc_topic)) {
                    handle_register_thing_response(event->data, event->data_len, true);
                } else if (is_topic_match(event->topic, event->topic_len, s_ctx->reg_rej_topic)) {
                    handle_register_thing_response(event->data, event->data_len, false);
                }
            }
            break;
            
        case MQTT_EVENT_ERROR:
        case MQTT_EVENT_DISCONNECTED:
            if (s_ctx->state != PROV_STATE_DONE && s_ctx->state != PROV_STATE_CONNECTING) {
                ESP_LOGE(TAG, "Connection lost or error during provisioning state: %d", s_ctx->state);
                notify_finish(ESP_FAIL);
            }
            break;

        default:
            break;
    }
}

/* --- Main Provisioning API --- */

esp_err_t fleet_provision_start(const char* claim_cert_pem, const char* claim_key_pem,
                                     const char* claim_id, const char* claim_token) {
                                         
    if (s_ctx != NULL) {
        ESP_LOGE(TAG, "Provisioning already in progress");
        return ESP_ERR_INVALID_STATE;
    }
    
    ESP_LOGI(TAG, "===== Starting Async AWS IoT Fleet Provisioning =====");
    
    s_ctx = calloc(1, sizeof(provisioning_ctx_t));
    if (!s_ctx) return ESP_ERR_NO_MEM;
    
    s_ctx->state = PROV_STATE_CONNECTING;
    s_ctx->claim_id = claim_id ? strdup(claim_id) : NULL;
    s_ctx->claim_token = claim_token ? strdup(claim_token) : NULL;

    devcfg_get_serial_number_str(s_ctx->serial_number, SERIAL_NUMBER_STR_SIZE);
             
    // Start the safety timeout timer
    s_ctx->timeout_timer = xTimerCreate("ProvTimeout", pdMS_TO_TICKS(PROV_OVERALL_TIMEOUT_MS), 
                                        pdFALSE, NULL, provisioning_timeout_cb);
    xTimerStart(s_ctx->timeout_timer, 0);
             
    // Connect to MQTT. The event handler takes over from here!
    mqtt_wrapper_config_t claim_cfg = {
        .client_id = s_ctx->serial_number,
        .client_cert_pem = claim_cert_pem,
        .client_key_pem = claim_key_pem,
        .event_handler = provisioning_mqtt_event_handler
    };
    
    esp_err_t ret = mqtt_wrapper_connect(&claim_cfg);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initiate MQTT connection for provisioning");
        notify_finish(ret);
        return ret;
    }
    
    // Return immediately to the caller. 
    return ESP_OK; 
}

#include "shadow_state.h"
#include "mqtt.h"
#include "device_config.h"
#include <shadow.h>
#include <core_json.h>
#include <string.h>

#define TAG "MQTT_SHADOW"
#define SHADOW_NAME_CONFIG "config"
#define SHADOW_TOPIC_MAX_LENGTH  ( 256U )

static char s_thing_name[128] = { 0 };
static size_t s_thing_name_len = 0;

void shadow_state_init()
{
    // Get thing name
    if (!devcfg_get_thing_name_str(s_thing_name, sizeof(s_thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name");
        ESP_ERROR_CHECK(ESP_ERR_INVALID_STATE);
    }
    s_thing_name_len = strlen(s_thing_name);
}

static void subscribe_to_shadow_topic(const char* shadow_name, ShadowTopicStringType_t topic_type) {
    char topic_buf[SHADOW_TOPIC_MAX_LENGTH];
    uint16_t topic_len = 0;

    ShadowStatus_t shadow_status = Shadow_AssembleTopicString(
        topic_type,
        s_thing_name, s_thing_name_len,
        shadow_name,
        strlen(shadow_name),
        topic_buf, sizeof(topic_buf),
        &topic_len
    );
    

    if (shadow_status == SHADOW_SUCCESS) {
        mqtt_subscribe(topic_buf, 1);
        ESP_LOGI(TAG, "Subscribed to: %s", topic_buf);
    } else {
        ESP_LOGE(TAG, "Failed to assemble shadow topic");
    }
}

void shadow_state_on_data(const char* topic, size_t topic_len, const char* payload, size_t payload_len)
{
    ShadowMessageType_t message_type;
    const char *p_thing_name_out = NULL;
    uint8_t thing_name_out_len = 0;
    const char *p_shadow_name_out = NULL;
    uint8_t shadow_name_out_len = 0;

    // Use core_shadow to figure out what topic this is
    ShadowStatus_t match_status = Shadow_MatchTopicString(
        topic, topic_len,
        &message_type,
        &p_thing_name_out, &thing_name_out_len,
        &p_shadow_name_out, &shadow_name_out_len
    );

    if (match_status == SHADOW_SUCCESS) {
        switch (message_type) {
            case ShadowMessageTypeUpdateDelta:
                ESP_LOGI(TAG, "Shadow Delta (Config Change) received! %s", payload);
                // After handling the delta, you should publish the new physical 
                // state back to the Update topic to clear the delta.
                break;
            case ShadowMessageTypeGetAccepted:
                ESP_LOGI(TAG, "Received Shadow Document! %s", payload);
                break;
            case ShadowMessageTypeGetRejected:
                ESP_LOGW(TAG, "Shadow Get request rejected.");
                break;
            default:
                ESP_LOGI(TAG, "Unhandled shadow message type: %d", message_type);
                break;
        }
    }
}

static void request_shadow_document(const char* shadow_name) {
    char topic_buf[SHADOW_TOPIC_MAX_LENGTH];
    uint16_t topic_len = 0;

    ShadowStatus_t shadow_status = Shadow_AssembleTopicString(
        ShadowTopicStringTypeGet,
        s_thing_name, strlen(s_thing_name),
        shadow_name,
        strlen(shadow_name),
        topic_buf, sizeof(topic_buf),
        &topic_len
    );

    if (shadow_status == SHADOW_SUCCESS) {
        // Publish an empty JSON payload to trigger the Get response
        mqtt_publish(topic_buf, "", 0, 1, 0);
        ESP_LOGI(TAG, "Published request to Get shadow document.");
    }
}

void shadow_state_on_connect()
{
    subscribe_to_shadow_topic(SHADOW_NAME_CONFIG, ShadowTopicStringTypeUpdateDelta);
    subscribe_to_shadow_topic(SHADOW_NAME_CONFIG, ShadowTopicStringTypeGetAccepted);
    subscribe_to_shadow_topic(SHADOW_NAME_CONFIG, ShadowTopicStringTypeGetRejected);
    request_shadow_document(SHADOW_NAME_CONFIG);
}
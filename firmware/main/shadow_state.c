#include "shadow_state.h"
#include "mqtt.h"
#include "device_config.h"
#include "supervisor.h"
#include <shadow.h>
#include <cJSON.h>
#include <stdlib.h>
#include <string.h>

#define TAG "MQTT_SHADOW"
#define SHADOW_NAME_SCHEDULE "schedule"
#define SHADOW_TOPIC_MAX_LENGTH  ( 256U )

#define NUM_SUBS 3
#define SUB_UPDATE_DELTA 0
#define SUB_GET_ACCEPTED 1
#define SUB_GET_REJECTED 2

typedef void (*shadow_state_delta_handler_t)(const char* delta, size_t len);

typedef struct {
    const char* shadow_name;
    shadow_state_delta_handler_t delta_handler;
    bool connection_subbed;
    int subs[NUM_SUBS];
    bool sub_state[NUM_SUBS];
} shadow_state_ctx_t;


static void schedule_delta_handler(const char* delta, size_t len);

static shadow_state_ctx_t s_shadows[] = {
    {
        .shadow_name = SHADOW_NAME_SCHEDULE,
        .delta_handler = schedule_delta_handler
    }
};

#define NUM_SHADOWS (sizeof(s_shadows) / sizeof(shadow_state_ctx_t))

static char s_thing_name[128] = { 0 };
static size_t s_thing_name_len = 0;
static bool s_shadow_ready_sent = false;

static esp_err_t patch_schedule_from_delta(device_schedule_t* sched, const char* delta, size_t size);
char* generate_aws_shadow_reported(const device_schedule_t* sched);

void shadow_state_init()
{
    // Get thing name
    if (!devcfg_get_thing_name_str(s_thing_name, sizeof(s_thing_name))) {
        ESP_LOGE(TAG, "Could not retrieve thing name");
        ESP_ERROR_CHECK(ESP_ERR_INVALID_STATE);
    }
    s_thing_name_len = strlen(s_thing_name);
}

static bool subscribe_to_shadow_topic(const char* shadow_name, ShadowTopicStringType_t topic_type, int* out_id) {
    char topic_buf[SHADOW_TOPIC_MAX_LENGTH + 1];
    uint16_t topic_len = 0;
    memset(topic_buf, 0, sizeof(topic_buf));

    ESP_LOGI(TAG, "Subscribing to shadow '%s' on topic type %d", shadow_name, topic_type);

    ShadowStatus_t shadow_status = Shadow_AssembleTopicString(
        topic_type,
        s_thing_name, s_thing_name_len,
        shadow_name,
        strlen(shadow_name),
        topic_buf, sizeof(topic_buf),
        &topic_len
    );
    

    if (shadow_status == SHADOW_SUCCESS) {
        mqtt_subscribe(topic_buf, 1, out_id);
        ESP_LOGI(TAG, "Subscribed to: %s with sub %d", topic_buf, *out_id);
        return true;
    } else {
        ESP_LOGE(TAG, "Failed to assemble shadow topic");
        return false;
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
        char* shadow_name = (char*)malloc(shadow_name_out_len + 1);
        memcpy(shadow_name, p_shadow_name_out, shadow_name_out_len);
        shadow_name[shadow_name_out_len] = '\0';

        switch (message_type) {
            case ShadowMessageTypeUpdateDelta:
                ESP_LOGI(TAG, "Shadow Delta (Config Change) received on topic %s", shadow_name);
                for (int i = 0; i < NUM_SHADOWS; i++) {
                    if (strcmp(shadow_name, s_shadows[i].shadow_name) == 0) {
                        s_shadows[i].delta_handler(payload, payload_len);
                    }
                }
                break;
            default:
                ESP_LOGI(TAG, "Unhandled shadow message type: %d", message_type);
                break;
        }
        free((void*)shadow_name);
    }

}

static void schedule_delta_handler(const char* delta, size_t len)
{
    ESP_LOGI(TAG, "Processing schedule delta");

    device_schedule_t* read_in_sched = (device_schedule_t*)malloc(sizeof(device_schedule_t));

    if (!read_in_sched) {
        ESP_ERROR_CHECK(ESP_ERR_NO_MEM);
    }

    // Copy in current schedule
    supervisor_get_schedule(read_in_sched);

    esp_err_t err;
    if ((err = patch_schedule_from_delta(read_in_sched, delta, len)) != ESP_OK) {
        ESP_LOGW(TAG, "Failed to process shadow schedule!");
        free(read_in_sched);
        return;
    }

    ESP_ERROR_CHECK(supervisor_submit_event_block(EVENT_SCHEDULE_DELTA_RECEIVED, (intptr_t)read_in_sched, 0));
}

static esp_err_t request_shadow(const char* shadow_name, ShadowTopicStringType_t topic_type,
        const char* payload, int len)
{
    char topic_buf[SHADOW_TOPIC_MAX_LENGTH];
    uint16_t topic_len = 0;

    ShadowStatus_t shadow_status = Shadow_AssembleTopicString(
        topic_type,
        s_thing_name, strlen(s_thing_name),
        shadow_name,
        strlen(shadow_name),
        topic_buf, sizeof(topic_buf),
        &topic_len
    );
    topic_buf[topic_len] = '\0';

    if (shadow_status == SHADOW_SUCCESS) {
        return mqtt_publish(topic_buf, payload, len, 1, 0);
    }
    return ESP_ERR_INVALID_ARG;
}

static esp_err_t request_shadow_document(const char* shadow_name)
{
    return request_shadow(shadow_name, ShadowTopicStringTypeGet, NULL, 0);
}

static esp_err_t update_shadow_document(const char* shadow_test, const char* payload, int len)
{
    return request_shadow(shadow_test, ShadowTopicStringTypeUpdate, payload, len);
}

static bool shadow_state_on_connect_ctx(shadow_state_ctx_t* ctx) {
    // Clear current subscription tracker
    memset(ctx->subs, 0, sizeof(ctx->subs));
    memset(ctx->sub_state, false, sizeof(ctx->sub_state));
    ctx->connection_subbed = false;
    s_shadow_ready_sent = false;


    if (!subscribe_to_shadow_topic(ctx->shadow_name, ShadowTopicStringTypeUpdateDelta,
         &ctx->subs[SUB_UPDATE_DELTA])) {
        return false;
    }

    if (!subscribe_to_shadow_topic(ctx->shadow_name, ShadowTopicStringTypeUpdateAccepted, 
        &ctx->subs[SUB_GET_ACCEPTED])) {
        return false;
    }

    if (!subscribe_to_shadow_topic(ctx->shadow_name, ShadowTopicStringTypeUpdateRejected,
         &ctx->subs[SUB_GET_REJECTED])) {
        return false;
    }
    return true;
}

void shadow_state_on_connect()
{
    for (int i = 0; i < NUM_SHADOWS; i++) {
        shadow_state_on_connect_ctx(&s_shadows[i]);
    }
}

static void shadow_state_on_subscribe_ctx(shadow_state_ctx_t* ctx, int sub_id)
{
    for (int i = 0; i < NUM_SUBS; i++) {
        if (ctx->subs[i] == sub_id) {
            ctx->sub_state[i] = true;
        }
    }

    if (!ctx->connection_subbed) {
        if (ctx->sub_state[SUB_UPDATE_DELTA]
             && ctx->sub_state[SUB_GET_ACCEPTED]
             && ctx->sub_state[SUB_GET_REJECTED]) {
            ctx->connection_subbed = true;
        }
    }
}

void shadow_state_on_subscribe(int sub_id)
{
    // Check if shadow state already ready
    if (s_shadow_ready_sent) {
        return;
    }

    bool all_subscribed = true;
    for (int i = 0; i < NUM_SHADOWS; i++) {
        shadow_state_on_subscribe_ctx(&s_shadows[i], sub_id);
        if(!s_shadows[i].connection_subbed) {
            all_subscribed = false;
        }
    }

    if (all_subscribed) {
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_SHADOW_READY));
        s_shadow_ready_sent = true;
    }
}

esp_err_t shadow_state_fetch_schedule()
{
    ESP_LOGI(TAG, "Fetching schedule");
    return request_shadow_document(SHADOW_NAME_SCHEDULE);
}

esp_err_t shadow_state_report_schedule(const device_schedule_t* schedule)
{
    esp_err_t err;
    char* json_str = generate_aws_shadow_reported(schedule);
    if (!json_str) {
        err = ESP_ERR_INVALID_ARG;
        goto cleanup;
    }

    ESP_LOGI(TAG, "Reporting schedule: %s", json_str);
    err = update_shadow_document(SHADOW_NAME_SCHEDULE, json_str, strlen(json_str));

cleanup:
    if (json_str) {
        free(json_str);
    }
    return err;
}

// --- Enum to String Mappings ---
static const char* DAY_STRINGS[] = {
    "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
};

static const char* TAKE_EFFECT_STRINGS[] = {
    "IMMEDIATE", "NEXT_RELOAD"
};

static const char* TYPE_STRINGS[] = {
    "SIMPLE"
};

// --- String to Enum Helpers ---
static device_schedule_day_of_week_t parse_day_of_week(const char* str) {
    for (int i = 0; i <= SCHED_SUNDAY; i++) {
        if (strcmp(str, DAY_STRINGS[i]) == 0) return (device_schedule_day_of_week_t)i;
    }
    return SCHED_MONDAY; // Default fallback
}

static device_schedule_take_effect_t parse_take_effect(const char* str) {
    if (strcmp(str, "IMMEDIATE") == 0) return SCHED_IMMEDIATE;
    return SCHED_NEXT_RELOAD; // Default fallback
}

static device_schedule_type_t parse_schedule_type(const char* str) {
    return SCHED_SIMPLE; // Only one supported currently
}

/**
 * @brief Serializes a device_schedule_t struct into a cJSON object.
 * @note The caller must call cJSON_Delete() on the returned pointer when finished.
 */
cJSON* serialize_device_schedule(const device_schedule_t* sched) {
    if (!sched) return NULL;

    cJSON* root = cJSON_CreateObject();
    if (!root) return NULL;

    // 1. If no schedule is set, nullify the top-level fields to clear them from the shadow.
    // Returning an empty object "{}" would leave the existing shadow state unchanged.
    if (sched->type == SCHED_NONE) {
        cJSON_AddNullToObject(root, "id");
        cJSON_AddNullToObject(root, "takeEffect");
        cJSON_AddNullToObject(root, "schedule");
        cJSON_AddNullToObject(root, "timezoneIana");
        cJSON_AddNullToObject(root, "timezonePosix");
        return root; 
    }

    // 2. Root level fields
    // Include 'id' if the string is populated; otherwise set to null to clear it
    if (sched->id[0] != '\0') {
        cJSON_AddStringToObject(root, "id", sched->id);
    } else {
        cJSON_AddNullToObject(root, "id");
    }
    
    // Map sched->take_effect (enum) to TAKE_EFFECT_STRINGS index safely.
    const char *take_effect_str = "UNKNOWN";
    {
        size_t take_effect_count = sizeof(TAKE_EFFECT_STRINGS) / sizeof(TAKE_EFFECT_STRINGS[0]);
        /* Guard against corrupted/uninitialized values that could be negative or out of range. */
        if (sched->take_effect >= 0 && (size_t)sched->take_effect < take_effect_count) {
            take_effect_str = TAKE_EFFECT_STRINGS[sched->take_effect];
        }
    }
    cJSON_AddStringToObject(root, "takeEffect", take_effect_str);

    // 3. Schedule object
    cJSON* schedule_obj = cJSON_AddObjectToObject(root, "schedule");
    
    const char *type_str = "UNKNOWN";
    /* Map sched->type (enum) to TYPE_STRINGS index safely.
     * device_schedule_type_t is expected to be SCHED_NONE = 0, SCHED_SIMPLE = 1.
     * TYPE_STRINGS[0] corresponds to SCHED_SIMPLE, so we subtract 1 after bounds checking.
     */
    if (sched->type > SCHED_NONE) {
        size_t type_index = (size_t)(sched->type - 1U);
        size_t type_count = sizeof(TYPE_STRINGS) / sizeof(TYPE_STRINGS[0]);
        if (type_index < type_count) {
            type_str = TYPE_STRINGS[type_index];
        }
    }
    cJSON_AddStringToObject(schedule_obj, "type", type_str);

    // 4. Bins Array
    if (sched->type == SCHED_SIMPLE) {
        // Generate the 'bins' array if there are actual bins configured,
        // otherwise explicitly set it to null to clear the array from the shadow.
        if (sched->schedule.simple_schedule.bin_count > 0) {
            cJSON* bins_arr = cJSON_AddArrayToObject(schedule_obj, "bins");
            
            for (uint8_t i = 0; i < sched->schedule.simple_schedule.bin_count; i++) {
                cJSON* bin_item = cJSON_CreateObject();
                
                // Add Day of Week
                {
                    const char *day_str = "UNKNOWN";
                    size_t day_count = sizeof(DAY_STRINGS) / sizeof(DAY_STRINGS[0]);
                    uint8_t dow = sched->schedule.simple_schedule.bins[i].day_of_week;
                    if (dow < day_count) {
                        day_str = DAY_STRINGS[dow];
                    }
                    cJSON_AddStringToObject(bin_item, "dayOfWeek", day_str);
                }
                
                // Format time as "HH:MM"
                char time_str[8];
                snprintf(time_str, sizeof(time_str), "%02d:%02d", 
                         sched->schedule.simple_schedule.bins[i].hour, 
                         sched->schedule.simple_schedule.bins[i].minute);
                cJSON_AddStringToObject(bin_item, "time", time_str);
                
                cJSON_AddItemToArray(bins_arr, bin_item);
            }
        } else {
            cJSON_AddNullToObject(schedule_obj, "bins");
        }
    }

    // 5. Timezone fields
    if (sched->timezone_iana[0] != '\0') {
        cJSON_AddStringToObject(root, "timezoneIana", sched->timezone_iana);
    } else {
        cJSON_AddNullToObject(root, "timezoneIana");
    }

    if (sched->timezone_posix[0] != '\0') {
        cJSON_AddStringToObject(root, "timezonePosix", sched->timezone_posix);
    } else {
        cJSON_AddNullToObject(root, "timezonePosix");
    }

    return root;
}

/**
 * @brief Generates an AWS IoT Shadow reported state JSON payload.
 * @note The caller MUST call free() on the returned string when done!
 * @return A null-terminated JSON string, or NULL on failure.
 */
char* generate_aws_shadow_reported(const device_schedule_t* sched) {
    if (!sched) return NULL;

    // 1. Create the root JSON object
    cJSON* root = cJSON_CreateObject();
    if (!root) return NULL;

    // 2. Create the "state" object inside root
    cJSON* state_obj = cJSON_AddObjectToObject(root, "state");
    if (!state_obj) {
        cJSON_Delete(root);
        return NULL;
    }

    // 3. Get the serialized schedule object from our core function
    // (This creates the object with "id", "takeEffect", and "schedule")
    cJSON* reported_obj = serialize_device_schedule(sched);
    if (!reported_obj) {
        cJSON_Delete(root);
        return NULL;
    }

    // 4. Attach the schedule data to the "state" object under the key "reported"
    // cJSON_AddItemToObject transfers memory ownership of reported_obj to root
    cJSON_AddItemToObject(state_obj, "reported", reported_obj);

    // 5. Render the JSON tree to a string
    // We use cJSON_PrintUnformatted instead of cJSON_Print to strip all tabs 
    // and newlines. This heavily reduces the MQTT payload size!
    char* json_string = cJSON_PrintUnformatted(root);

    // 6. Clean up the cJSON tree 
    // (This safely and recursively frees root, state_obj, and reported_obj)
    cJSON_Delete(root);

    if (!json_string) {
        ESP_LOGE(TAG, "Failed to allocate memory for JSON string");
    }

    return json_string;
}

esp_err_t patch_schedule_from_delta(device_schedule_t* schedule, const char* delta_json_str, size_t size) {
    if (!schedule || !delta_json_str) {
        return ESP_ERR_INVALID_ARG;
    }

    cJSON* root = cJSON_ParseWithLength(delta_json_str, size);
    if (!root) {
        ESP_LOGE(TAG, "Failed to parse delta JSON");
        return ESP_FAIL;
    }

    // 1. Navigate through the AWS IoT Shadow envelope. 
    // A raw delta arrives as {"state": { ... }, "metadata": { ... } }
    cJSON* state = cJSON_GetObjectItem(root, "state");
    if (!state) {
        // Fallback: If "state" isn't found, assume the root IS the delta state.
        state = root; 
    }

    // 2. Update 'id' if present
    cJSON* id_item = cJSON_GetObjectItem(state, "id");
    if (cJSON_IsString(id_item) && id_item->valuestring != NULL) {
        snprintf(schedule->id, sizeof(schedule->id), "%s", id_item->valuestring);
    }

    // 3. Update 'takeEffect' if present
    cJSON* take_effect_item = cJSON_GetObjectItem(state, "takeEffect");
    if (cJSON_IsString(take_effect_item) && take_effect_item->valuestring != NULL) {
        schedule->take_effect = parse_take_effect(take_effect_item->valuestring);
    }

    // 4. Locate the schedule object
    // Based on serialize_device_schedule(), 'type' and 'bins' are inside 'schedule'.
    cJSON* schedule_obj = cJSON_GetObjectItem(state, "schedule");
    if (!schedule_obj) {
        // Fallback for the flat JSON structure provided in your example
        schedule_obj = state; 
    }

    // 5. Update 'type' if present
    cJSON* type_item = cJSON_GetObjectItem(schedule_obj, "type");
    if (cJSON_IsString(type_item) && type_item->valuestring != NULL) {
        schedule->type = parse_schedule_type(type_item->valuestring);
    }

    // 6. Update 'bins' array if present
    cJSON* bins_arr = cJSON_GetObjectItem(schedule_obj, "bins");
    if (cJSON_IsArray(bins_arr)) {
        // AWS IoT Shadow arrays overwrite entirely. If "bins" is in the delta,
        // it contains the complete new array.
        int bin_count = cJSON_GetArraySize(bins_arr);

        // Reject schedules that exceed the 14-bin limit instead of silently truncating.
        if (bin_count > 14) {
            ESP_LOGW(TAG, "Rejecting schedule: bins array too large (%d > 14)", bin_count);
            cJSON_Delete(root);
            return ESP_ERR_INVALID_ARG;
        }

        // Parse into a temporary array so we don't partially update the schedule
        device_bin_schedule_t tmp_bins[14];
        uint8_t tmp_bin_count = 0;

        for (int i = 0; i < bin_count; i++) {
            cJSON* bin_item = cJSON_GetArrayItem(bins_arr, i);
            if (!cJSON_IsObject(bin_item)) {
                // Skip non-object entries
                continue;
            }

            cJSON* day_item = cJSON_GetObjectItem(bin_item, "dayOfWeek");
            cJSON* time_item = cJSON_GetObjectItem(bin_item, "time");

            if (cJSON_IsString(day_item) && cJSON_IsString(time_item) &&
                day_item->valuestring != NULL && time_item->valuestring != NULL) {

                if (tmp_bin_count >= 14) {
                    // Should not happen due to bin_count check above, but guard anyway.
                    ESP_LOGW(TAG, "Internal error: tmp_bin_count exceeded 14");
                    break;
                }

                device_bin_schedule_t* new_bin = &tmp_bins[tmp_bin_count];

                // Parse day of week from string
                new_bin->day_of_week = parse_day_of_week(day_item->valuestring);

                // Parse "HH:MM" into integers and validate ranges
                unsigned int hour = 0, minute = 0;
                if (sscanf(time_item->valuestring, "%2u:%2u", &hour, &minute) == 2 &&
                    hour < 24 && minute < 60) {
                    new_bin->hour = (uint8_t)hour;
                    new_bin->minute = (uint8_t)minute;

                    tmp_bin_count++;
                } else {
                    ESP_LOGW(TAG, "Invalid time string in schedule bin: %s", time_item->valuestring);
                    // Skip this bin; do not add it to the schedule
                }
            }
        }

        // Now that parsing and validation are complete, overwrite the existing schedule.
        schedule->schedule.simple_schedule.bin_count = tmp_bin_count;
        if (tmp_bin_count > 0) {
            memcpy(schedule->schedule.simple_schedule.bins,
                   tmp_bins,
                   tmp_bin_count * sizeof(device_bin_schedule_t));
        }
    }

    // 7. Parse timezoneIana if present
    cJSON* tz_iana_item = cJSON_GetObjectItem(state, "timezoneIana");
    if (cJSON_IsString(tz_iana_item) && tz_iana_item->valuestring != NULL) {
        if (strlen(tz_iana_item->valuestring) >= TIMEZONE_IANA_SIZE) {
            ESP_LOGW(TAG, "Rejecting schedule: timezoneIana too long (%d >= %d)",
                     (int)strlen(tz_iana_item->valuestring), TIMEZONE_IANA_SIZE);
            cJSON_Delete(root);
            return ESP_ERR_INVALID_ARG;
        }
        snprintf(schedule->timezone_iana, TIMEZONE_IANA_SIZE, "%s", tz_iana_item->valuestring);
    }

    // 8. Parse timezonePosix if present
    cJSON* tz_posix_item = cJSON_GetObjectItem(state, "timezonePosix");
    if (cJSON_IsString(tz_posix_item) && tz_posix_item->valuestring != NULL) {
        if (strlen(tz_posix_item->valuestring) >= TIMEZONE_POSIX_SIZE) {
            ESP_LOGW(TAG, "Rejecting schedule: timezonePosix too long (%d >= %d)",
                     (int)strlen(tz_posix_item->valuestring), TIMEZONE_POSIX_SIZE);
            cJSON_Delete(root);
            return ESP_ERR_INVALID_ARG;
        }
        snprintf(schedule->timezone_posix, TIMEZONE_POSIX_SIZE, "%s", tz_posix_item->valuestring);
    }

    // Clean up
    cJSON_Delete(root);
    return ESP_OK;
}
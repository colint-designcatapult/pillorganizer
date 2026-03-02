#include "network.h"
#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include <esp_http_client.h>
#include "util.h"
#include <event.h>
#include "pill_state.h"
#include "nvs_wrapper.h"
#include "engineering.h"
#include "ota.h"
#include <nvs.h>

#include "pb_encode.h"
#include "pb_decode.h"

#include "wifi.h"
#include "wire_codec.h"
#include "ble.h"
#include <esp_bt.h>
#include <string.h>

#define TAG "NETWORK"

//Need to define Blob:
//OOB_key
//server-url

TaskHandle_t task_handle = NULL;


typedef struct {
    uint8_t oob_key[16];
    bool registered;
    uint32_t event_ctr;
} provision_record_t;

provision_record_t provision_record = {0};
char* bearer_token = NULL;
#define NVS_TAG_OOB_KEY "PRECORD"

typedef struct {
    bool custom_url;
    uint16_t  wLen;
	uint8_t   awBuf[256];
} __attribute__((packed)) URL_FORMAT_t;

#define NVS_TAG_OTA_URL "OTAURL"
#define DEFAUT_HOST "jctbackend.herokuapp.com"
URL_FORMAT_t  stCustomUrl = {0};

bool network_send_provision();

static esp_err_t save_provision_record() {
    return nvs_write_blob(NVS_TAG_OOB_KEY, &provision_record, sizeof(provision_record));
}

static esp_err_t load_provision_record() {
    return nvs_read_blob(NVS_TAG_OOB_KEY, &provision_record, sizeof(provision_record));
}

static esp_err_t load_ota_host_record() {
    //1byte true/false + 2 byte length + url string = blob size
    esp_err_t err;

    err = nvs_read_blob(NVS_TAG_OTA_URL, &stCustomUrl, sizeof(stCustomUrl));

    if( err != ESP_OK && err != ESP_ERR_NVS_NOT_FOUND ) {
		ESP_LOGE(TAG, "Can't find url %x, len:%d\n", err, stCustomUrl.wLen);
		return err;
    }
    else {
        ESP_LOGE(TAG, "Found url %x, len:%d\n", err, stCustomUrl.wLen);

        //if the url is found and len > 0, there was correct url was set
        if( stCustomUrl.wLen > 0) 
        {
            ESP_LOGI(TAG, "Found saved url blob size:%d, %d\n", stCustomUrl.custom_url, stCustomUrl.wLen);
            return ESP_OK;
        }
        else 
        {
            //return Fail if the len  =0 meaning no URL was saved
            return ESP_FAIL;
        }
    }
}

bool encode_oob_key(pb_ostream_t *stream, const pb_field_t *field, void * const *arg)
{
    if (!pb_encode_tag_for_field(stream, field))
        return false;

    return pb_encode_string(stream, (uint8_t*)provision_record.oob_key, sizeof(provision_record.oob_key));
}

// Provisioning helpers for BLE
esp_err_t network_set_certificate(const uint8_t* cert, size_t len)
{
    if(len != sizeof(provision_record.oob_key))
        return ESP_ERR_INVALID_ARG;

    memcpy(provision_record.oob_key, cert, len);

    esp_err_t err = save_provision_record();
    ESP_LOGI(TAG, "Set certificate exited with %d", err);
    return err;
}

void network_get_serial_number(uint8_t* sn_out, size_t* len_out)
{
    const wifi_info_t* wifi_info = wifi_get_info();
    memcpy(sn_out, wifi_info->sn.bytes.mac, 6);
    *len_out = 6;
}

// Save PEM certificate/key to NVS
esp_err_t network_save_cert_to_nvs(const char* nvs_key, const char* cert_pem)
{
    return nvs_write_blob(nvs_key, cert_pem, strlen(cert_pem) + 1);
}

// Load PEM certificate/key from NVS (caller must free *cert_out)
esp_err_t network_load_cert_from_nvs(const char* nvs_key, char** cert_out, size_t* len_out)
{
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READONLY, &h);
    if (err != ESP_OK) return err;

    size_t required_size = 0;
    err = nvs_get_blob(h, nvs_key, NULL, &required_size);
    if (err != ESP_OK) {
        nvs_close(h);
        return err;
    }

    *cert_out = malloc(required_size);
    if (*cert_out == NULL) {
        nvs_close(h);
        return ESP_ERR_NO_MEM;
    }

    err = nvs_get_blob(h, nvs_key, *cert_out, &required_size);
    nvs_close(h);
    if (err != ESP_OK) {
        free(*cert_out);
        *cert_out = NULL;
        return err;
    }

    if (len_out) *len_out = required_size;
    return ESP_OK;
}

// Save Thing name to NVS
esp_err_t network_save_thing_name(const char* thing_name)
{
    return nvs_write_blob("THING_NAME", thing_name, strlen(thing_name) + 1);
}

// Load Thing name from NVS
esp_err_t network_load_thing_name(char* thing_name_out, size_t max_len)
{
    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READONLY, &h);
    if (err != ESP_OK) return err;

    size_t len = max_len;
    err = nvs_get_blob(h, "THING_NAME", thing_name_out, &len);
    nvs_close(h);
    if (err != ESP_OK) return err;

    ESP_LOGI(TAG, "Loaded Thing name from NVS: %s", thing_name_out);
    return ESP_OK;
}

void network_bin_event_task(void* parm);

void start_task()
{
    create_task_with_watchdog(network_bin_event_task, "BIN_EVENT_UPLOAD_TASK", 8192, NULL, 3);
    esp_task_wdt_add(task_handle);
    ESP_LOGI(TAG, "Started network task");
}

void stop_task()
{
    esp_task_wdt_delete(task_handle);
    vTaskDelete(task_handle);
}

/*void network_wifi_connect(const wifi_info_t*  info, bool just_provisioned)
{
    wifi_info = info;
    ESP_LOGI(TAG, "Connected to wifi '%s' just provisioned= %d", info->ssid, just_provisioned);
    if(just_provisioned) {
        engineering_restart(5000);
        return;
    }
    connected = true;

    engineering_start_server();
}

void network_wifi_disconnect()
{
    ESP_LOGI(TAG, "Disconnected from wifi");
    connected = false;

    engineering_stop_server();
}*/

bool decode_authorization(pb_istream_t *stream, const pb_field_iter_t *field, void **arg)
{
    size_t auth_size = stream->bytes_left;
    if(auth_size > 1024)
        return false;

    if(bearer_token != NULL) {
        free(bearer_token);
        bearer_token = NULL;
    }

    const char* prefix = "Bearer ";
    size_t prefix_size = strlen(prefix);
    size_t total_size = auth_size + prefix_size + 1;
    ESP_LOGI(TAG, "Authorization header size %d total %d", auth_size, total_size);

    bearer_token = malloc(total_size);
    strcpy(bearer_token, "Bearer ");
    char* write_to = bearer_token + prefix_size;

    if(!pb_read(stream, (pb_byte_t*)write_to, auth_size))
        return false;

    // Write terminator to end of string
    write_to[auth_size] = '\0';

    ESP_LOGI(TAG, "Authorization token %s", bearer_token);

    return true;
}

static char *get_host_url()
{
    if(stCustomUrl.custom_url == true)
    {
        return (char *)&stCustomUrl.awBuf[0];
    }
    else 
    {
        return " ";//DEFAUT_HOST; //stop sending the default one to make sure the provision is correctly done
    }

}

void network_build_base_config(esp_http_client_config_t* config, const char* path,
        esp_http_client_method_t method)
{
    config->path = path;
    config->method = method;
    config->keep_alive_enable = true;
    config->timeout_ms = 10000;
// switch between server hosted on PC and the digital ocean one
#if 1  // Changed to 0 to use local server for OTA development
    config->host                        = get_host_url();
    //config->host                      = //"cabinet-staging-a663e71fb1a6.herokuapp.com"; //t-b suggested
    config->port                        = 443;
    config->auth_type                   = HTTP_AUTH_TYPE_NONE;
    config->transport_type              = HTTP_TRANSPORT_OVER_SSL;
    config->skip_cert_common_name_check = true;

#else
    config->host                        = "192.168.1.103";  // Updated to current local IP
    config->port                        = 8080;
    config->auth_type                   = HTTP_AUTH_TYPE_NONE;
    config->transport_type              = HTTP_TRANSPORT_OVER_TCP;
    config->skip_cert_common_name_check = true;
#endif
}



#define CHECK_HTTP_ERROR(x) ({                                         \
        result = (x);                                                  \
        if (unlikely(result < 0)) {                              \
            printf(#x "\n"); \
            goto cleanup;                                              \
        }                                                              \
        result;                                                        \
    })

static esp_err_t network_send_protobuf_request_internal(const char* path, esp_http_client_method_t method,
    const uint8_t* req_body, size_t req_size, int* status_out, const pb_msgdesc_t* fields, void* dest_struct, bool bearer)
{

    // Immediately initialize the status code to -1
    *status_out = -1;
    esp_err_t result = ESP_FAIL;

    esp_http_client_config_t config = { 0 };
    network_build_base_config(&config, path, method);

    esp_http_client_handle_t cli_handle = esp_http_client_init(&config);
    if(cli_handle == NULL)
        return ESP_FAIL;


    // If a request body is specified, set the post field to the encoded PB structure and set content type
    if(req_body != NULL) {
        CHECK_HTTP_ERROR(esp_http_client_set_header(cli_handle, "Content-Type", "application/x-protobuf"));

        if(bearer_token != NULL && bearer) {
            CHECK_HTTP_ERROR(esp_http_client_set_header(cli_handle, "Authorization", bearer_token));
        }

        CHECK_HTTP_ERROR(esp_http_client_open(cli_handle, req_size));
        // disabled with streaming api
        //esp_http_client_set_post_field(cli_handle, (const char*)req_body->state, req_body->bytes_written);

        if(esp_http_client_write(cli_handle, (const char*)req_body, req_size) < 0) {
            result = ESP_FAIL;
            goto cleanup;
        }
    } else {
        CHECK_HTTP_ERROR(esp_http_client_open(cli_handle, 0));
    }

    // disabled with streaming api
    //CHECK_HTTP_ERROR(esp_http_client_perform(cli_handle));

    int content_len = esp_http_client_fetch_headers(cli_handle);
    if(content_len < 0) {
        result = ESP_FAIL;
        goto cleanup;
    } else if(content_len > 4096) {
        // Cap response length to 4096 bytes, which should be more than enough
        result = ESP_ERR_INVALID_RESPONSE;
        goto cleanup;
    }


    if(fields != NULL && dest_struct != NULL) {
        char* buffer = malloc(content_len);
        CHECK_HTTP_ERROR(esp_http_client_read_response(cli_handle, buffer, content_len));
        pb_istream_t stream = pb_istream_from_buffer((pb_byte_t*)buffer, content_len);
        if(!pb_decode(&stream, fields, dest_struct)) {
            result = ESP_FAIL;
            free(buffer);
            goto cleanup;
        }
        free(buffer);
    } else {
        int len = 0;
        CHECK_HTTP_ERROR(esp_http_client_flush_response(cli_handle, &len));
    }

    // Set status code to real response status
    *status_out = esp_http_client_get_status_code(cli_handle);

    result = ESP_OK;

cleanup:
    esp_http_client_cleanup(cli_handle);

    return result;
}

uint64_t swap_long(uint64_t x) {
x = (x & 0x00000000FFFFFFFF) << 32 | (x & 0xFFFFFFFF00000000) >> 32;
x = (x & 0x0000FFFF0000FFFF) << 16 | (x & 0xFFFF0000FFFF0000) >> 16;
x = (x & 0x00FF00FF00FF00FF) << 8  | (x & 0xFF00FF00FF00FF00) >> 8;
return x;
}

static esp_err_t network_send_protobuf_request(const char* path, esp_http_client_method_t method,
    const uint8_t* req_body, size_t req_size, int* status_out, const pb_msgdesc_t* fields, void* dest_struct)
{
    int status;
    esp_err_t err;
    if((err = network_send_protobuf_request_internal(path, method, req_body, req_size, &status,
            fields, dest_struct, true)) != ESP_OK) {
        return err;
    } else {
        if(status_out)
            *status_out = status;

        // If unauthorized, try authorizing the request
        if(status == 401) {
            AuthorizeRequest authReq = AuthorizeRequest_init_zero;
            const wifi_info_t*  wifi_info = wifi_get_info();
            int64_t sn = (int64_t)swap_long(wifi_info->sn.sn);
            uint8_t* bytes = (uint8_t*)&sn;
            authReq.serial_no = sn;
            
            ESP_LOGI(TAG, "Using serial number %x%x%x%x%x%x%x%x %lld", bytes[0], bytes[1],
                    bytes[2], bytes[3],bytes[4],bytes[5],bytes[6],bytes[7], authReq.serial_no);
            authReq.oob_key.funcs.encode = &encode_oob_key;

            uint8_t buffer[128];
            pb_ostream_t ostream = pb_ostream_from_buffer(buffer, sizeof(buffer));
            pb_encode(&ostream, AuthorizeRequest_fields, &authReq);

            AuthorizeResponse resp = AuthorizeResponse_init_zero;
            resp.access_token.funcs.decode = &decode_authorization;

            err = network_send_protobuf_request_internal("/api/v1_2/device/auth", HTTP_METHOD_POST, buffer,
                    ostream.bytes_written, &status, AuthorizeResponse_fields, &resp, false);

            if(status_out)
                *status_out = status;

            if(err == ESP_OK && status == 200) {
                on_authentication_success();

                // Retry request
                return network_send_protobuf_request_internal(path, method, req_body, req_size, status_out,
            fields, dest_struct, true);
            }
        }
        return err;
    }
}

static esp_err_t network_send_protobuf_request_ff(const char* path, esp_http_client_method_t method,
    const uint8_t* req_body, size_t req_size, int* status_out)
{
    return network_send_protobuf_request(path, method, req_body, req_size, status_out, NULL, NULL);
}

static esp_err_t network_send_protobuf_request_eb(const char* path, esp_http_client_method_t method, int* status_out)
{
    return network_send_protobuf_request_ff(path, method, NULL, 0, status_out);
}

static void handle_sync_response(SyncResponse* resp) {
    ESP_LOGI(TAG, "Handling sync response %" PRIi32, resp->latest_firmware);
    state_set_schedule(resp->schedule, resp->schedule_count);
    if(resp->has_bin_state) {
        state_set_state(&resp->bin_state);
    }
    ota_handle_sync(resp);
}

bool network_send_provision()
{
    DeviceProvisionRequest req = DeviceProvisionRequest_init_zero;
    req.bssid.funcs.encode = &encode_bssid;
    req.ssid.funcs.encode = &encode_ssid;

    uint8_t buffer[256];
    pb_ostream_t ostream = pb_ostream_from_buffer(buffer, sizeof(buffer));
    pb_encode(&ostream, DeviceProvisionRequest_fields, &req);
    // ESP_LOGI(TAG, "Encoded provision record");

    SyncResponse resp = SyncResponse_init_zero;

    int status;
    esp_err_t res = network_send_protobuf_request("/api/v1_2/device/provision",
            HTTP_METHOD_POST, buffer, ostream.bytes_written, &status, SyncResponse_fields, &resp);

    // ESP_LOGI(TAG, "Provision status %d esp_err_t %d", status, res);
    if(res == ERR_OK) {
        if(status == 200) {

            // Provision successful
            provision_record.registered = true;
            save_provision_record();

            handle_sync_response(&resp);
        
            return pdTRUE;
        }
    }
    return pdFALSE;
}

static void network_send_sync() {
    SyncRequest req = SyncRequest_init_zero;
    encode_sync_request(&req, false);

    //ESP_LOGI(TAG, "Charger status %d", (uint8_t)req.engr_data.has_vbat_scaled);

    uint8_t buffer[512];
    pb_ostream_t ostream = pb_ostream_from_buffer(buffer, sizeof(buffer));
    pb_encode(&ostream, SyncRequest_fields, &req);

    SyncResponse resp = SyncResponse_init_zero;
        int status;
    esp_err_t res = network_send_protobuf_request("/api/v1_2/device/sync",
            HTTP_METHOD_POST, buffer, ostream.bytes_written, &status, SyncResponse_fields, &resp);
    
    if(res == ERR_OK && status == 200) {
        handle_sync_response(&resp);
    }
}


void on_authentication_success()
{
    ESP_LOGI(TAG, "Authentication success starting bin events upload");
}

void network_bin_event_task(void* parm)
{
    for(;;) {
        if(wifi_is_connected()) {
            // TODO: Engineering server breaks compilation after ESP-IDF 6.9.0 upgrade
            // engineering_start_server(); // reentrant

            // Device registration handled by AWS IoT Fleet Provisioning
            bool registered = true;

            if(registered) {
                //if the device is provisioned and not connect to BT
                //device will send sync data every 20seconds
                if(!ble_has_sync_preemption()) {
                    BinEvent be = { 0 };
                    bool has_bin_event = false;
                    for(int i = 0; i < 20; i++) {
                        vTaskDelay(pdMS_TO_TICKS(1000));
                        if(xQueuePeek(event_bin_queue(), &be, 0)) {
                            // If events are waiting, break off the delay loop and sync immediately
                            has_bin_event = true;
                            break;
                        }
                    }

                    SemaphoreHandle_t sem = event_bin_queue_mutex();
                    if(xSemaphoreTake(sem, 0)) {
                        // network_send_sync(); // Legacy HTTP backend - replaced by AWS IoT MQTT telemetry
                        xSemaphoreGive(sem);
                    }
                } else {
                    // Bluetooth has preemption, so do nothing
                    vTaskDelay(pdMS_TO_TICKS(1000));
                }
            } else {
                // Failed to register
                // Try again in 5 seconds.
                vTaskDelay(pdMS_TO_TICKS(5000));
            }

        } else {
            // TODO: Engineering server breaks compilation after ESP-IDF 6.9.0 upgrade 
            // engineering_stop_server(); // reentrant
            vTaskDelay(pdMS_TO_TICKS(1000));
        }
        esp_task_wdt_reset();
    }
}


void network_init()
{
 
    //read back backend url
    esp_err_t err = load_ota_host_record();

    //read back provision record
    err = load_provision_record();

    if(err == ESP_OK) {
        ESP_LOGI(TAG, "Provision Record Found Using it\n");
    }
    else if(ESP_ERR_NVS_NOT_FOUND == err || ESP_ERR_INVALID_SIZE == err) {
        // bin schedule not persisted yet, initialize to zero & persist
        ESP_LOGI(TAG, "ESP_ERR_NVS_NOT_FOUND or ESP_ERR_INVALID_SIZE error, reset precord");
        memset(&provision_record, 0, sizeof(provision_record));
        save_provision_record();
        //esp_restart();
    } else {
        ESP_LOGI(TAG, "Error: %x, perform nvs factory reset", err);
        nvs_factory_reset();
        ESP_ERROR_CHECK(err);
    }

    start_task();

}


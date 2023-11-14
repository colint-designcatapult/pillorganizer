#include "engineering.h"
#include <time.h>
#include <esp_log.h>
#include <esp_http_server.h>
#include <esp_ota_ops.h>
#include "pb_encode.h"
#include "pill_state.h"
#include "freertos/ringbuf.h"

#include "pill_gpio.h"
#include "nvs_wrapper.h"
#include "ota.h"
#include "wifi.h"
#include "event.h"

#define TAG "ENGR"

SemaphoreHandle_t engr_sphr = { 0 };
EngineeringRequest req = EngineeringRequest_init_zero;
EngineeringData data = EngineeringData_init_default;
bool engr_mode = false;

RingbufHandle_t buf_handle;


bool engineering_mode()
{
    return engr_mode;
}

void engineering_handle_sync(SyncResponse* sync)
{
    if(!engr_mode && sync->engr_mode) {
        ESP_LOGI(TAG, "Engineering mode enabled");
        led_set_effect(LED_EFFECT_FLASH_GREEN_AND_RED, 12);
    }


    engr_mode = sync->engr_mode;
}


EngineeringRequest* engineering_request()
{
    return &req;
}

static void engineering_set_samples(size_t voltage_count, uint32_t* voltages, uint32_t vbat_meas)
{

    if(xSemaphoreTake(engr_sphr, pdMS_TO_TICKS(500)) == pdTRUE) {
       // gpio_set_level(TP18, 1);
        data.has_vbat_meas = true;
        data.vbat_meas = voltages[14];   //mux_14 is battery input 

        //vbat_meas; //vbat_meas is meaning less, no data in this variable
        
        time_t now;
        time(&now);
        data.timestamp = (int64_t)now;

        data.voltages_count = voltage_count;
        memcpy(data.voltages, voltages, voltage_count * sizeof(int32_t));
        xSemaphoreGive(engr_sphr);
        //gpio_set_level(TP18, 0);
    } else {
        ESP_LOGW(TAG, "Could not upload samples, engineering locked?");
    }

}

void engineering_print_samples() {
    if(xSemaphoreTake(engr_sphr, pdMS_TO_TICKS(500)) == pdTRUE) {
        printf("=============================\n");
        printf(" MUX samples as of %lld\n", data.timestamp);
        for(int i = 0; i < data.voltages_count; i++) {
            printf(" Ch %d\t%d mV\n", (int)i, (int)data.voltages[i]);
        }
        printf("=============================\n");
        xSemaphoreGive(engr_sphr);
    } else {
        printf("Could not obtain sample lock in time. Try again (possible deadlock condition?)\n");
    }
}

void engineering_build_sync(SyncRequest* sync)
{
    sync->has_engr_data = true;
    memcpy(&sync->engr_data, &data, sizeof(EngineeringData));
}

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

extern const char engineering_html_start[] asm("_binary_engineering_html_start");
extern const char engineering_html_end[] asm("_binary_engineering_html_end");

/* Our URI handler function to be called during GET /uri request */
esp_err_t get_handler(httpd_req_t *req)
{
    /* Send a simple response */
    httpd_resp_send(req, engineering_html_start, engineering_html_end - engineering_html_start);
    return ESP_OK;
}

esp_err_t get_logs_handler(httpd_req_t* req) {

    size_t size;
    char* msg;
    while((msg = (char*)xRingbufferReceive(buf_handle, &size, 1)) != NULL) {
        if(httpd_resp_send_chunk(req, msg, size) != ESP_OK)
            break;
        vRingbufferReturnItem(buf_handle, msg);
    }
    httpd_resp_send_chunk(req, NULL, 0);
    return ESP_OK;
}

esp_err_t get_version_handler(httpd_req_t *req)
{
    const esp_partition_t* running = esp_ota_get_running_partition();

    esp_app_desc_t running_app_info;
    char* espver = "";
    if (esp_ota_get_partition_description(running, &running_app_info) == ESP_OK) {
        espver = running_app_info.version;
    }

    uint32_t free = esp_get_free_heap_size() / 1000;
    char fullstr[64];
    sprintf(fullstr, "%d (%s) %ld kb free", FIRMWARE_REVISION, espver, free);
    httpd_resp_sendstr(req, fullstr);
    return ESP_OK;
}

esp_err_t get_bins_state(httpd_req_t *req)
{
    EngineeringAllBins ab = EngineeringAllBins_init_default;
    ab.bins_count = 14;

    const bin_state_t* bs = state_acquire_ro();
    temp_state_t* temp = state_temp();
    for(bin_id_t i = 0; i < BIN_COUNT; i++) {
        EngineeringBinState* write = &ab.bins[i];
        write->open = temp[i].open;
        write->scheduled_time = bs[i].schedule_time;
        write->status = bs[i].status;
        write->voltage = data.voltages[i];
    }
    state_release_ro(bs);

    uint8_t buffer[256];
    pb_ostream_t ostream = pb_ostream_from_buffer(buffer, sizeof(buffer));
    pb_encode(&ostream, EngineeringAllBins_fields, &ab);
    httpd_resp_send(req, (char*)buffer, ostream.bytes_written);

    return ESP_OK;
}

esp_err_t post_reboot_handler(httpd_req_t *req) {
    httpd_resp_set_status(req, "302 Found");
    httpd_resp_set_hdr(req, "Location", "/");
    httpd_resp_send(req, NULL, 0);
    engineering_restart(1000);
    return ESP_OK;
}

esp_err_t post_reset_handler(httpd_req_t *req) {
    httpd_resp_set_status(req, "302 Found");
    httpd_resp_set_hdr(req, "Location", "/");
    httpd_resp_send(req, NULL, 0);
    nvs_factory_reset();
    engineering_restart(1000);
    return ESP_OK;
}

esp_err_t post_update_handler(httpd_req_t *req) {
    esp_err_t err;
    ota_progress_t prog;
    if((err = ota_start(&prog)) != ESP_OK)
        return err;

    int bytes_remaining = req->content_len; 
    ESP_LOGI(TAG, "Content len %d", bytes_remaining);

    int read;
    char buf[256];
    while((read = httpd_req_recv(req, buf, MIN(bytes_remaining, 256))) > 0) {
        if((err = ota_upload_part(&prog, buf, read)) != ESP_OK) {
            ESP_LOGW(TAG, "Unexpected error in OTA %d", err);
            ota_cancel(&prog);
            return err;
        }
    }
    err = ota_finish(&prog);
    if(err == ESP_OK)
        engineering_restart(1000);
    return err;
}




/* URI handler structure for GET / */
httpd_uri_t uri_get = {
    .uri      = "/",
    .method   = HTTP_GET,
    .handler  = get_handler,
    .user_ctx = NULL
};

httpd_uri_t uri_version = {
    .uri      = "/version",
    .method   = HTTP_GET,
    .handler  = get_version_handler,
    .user_ctx = NULL
};

httpd_uri_t uri_bins = {
    .uri      = "/bins",
    .method   = HTTP_GET,
    .handler  = get_bins_state,
    .user_ctx = NULL
};

httpd_uri_t uri_logs = {
    .uri      = "/logs",
    .method   = HTTP_GET,
    .handler  = get_logs_handler,
    .user_ctx = NULL
};


httpd_uri_t uri_reboot = {
    .uri      = "/reboot",
    .method   = HTTP_POST,
    .handler  = post_reboot_handler,
    .user_ctx = NULL
};

httpd_uri_t uri_reset = {
    .uri      = "/reset",
    .method   = HTTP_POST,
    .handler  = post_reset_handler,
    .user_ctx = NULL
};

httpd_uri_t uri_update = {
    .uri      = "/update",
    .method   = HTTP_POST,
    .handler  = post_update_handler,
    .user_ctx = NULL
};



/* Function for starting the webserver */
httpd_handle_t start_webserver(void)
{
    /* Generate default configuration */
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();

    /* Empty handle to esp_http_server */
    httpd_handle_t server = NULL;

    /* Start the httpd server */
    if (httpd_start(&server, &config) == ESP_OK) {
        /* Register URI handlers */
        httpd_register_uri_handler(server, &uri_get);
        httpd_register_uri_handler(server, &uri_version);
        httpd_register_uri_handler(server, &uri_bins);
        httpd_register_uri_handler(server, &uri_logs);
        httpd_register_uri_handler(server, &uri_reboot);
        httpd_register_uri_handler(server, &uri_reset);
        httpd_register_uri_handler(server, &uri_update);
    }
    /* If server failed to start, handle will be NULL */
    return server;
}

httpd_handle_t handle = NULL;

/* Function for stopping the webserver */
void stop_webserver(httpd_handle_t server)
{
    if (server) {
        /* Stop the httpd server */
        httpd_stop(server);
    }
}

void engineering_start_server()
{
    if(handle == NULL) {
        handle = start_webserver();
    }
}

void engineering_stop_server()
{
    if(handle != NULL) {
        stop_webserver(handle);
        handle = NULL;
    }
}

vprintf_like_t original_vprintf;

int print_original(const char* str, ...) {
    va_list ap;
    va_start(ap, str);
    int r = original_vprintf(str, ap);
    va_end(ap);
    return r;
}

int engineering_vprintf(const char* str, va_list args) {

    int size = original_vprintf(str, args);
    if(size > 0) {
        if(size > 128) {
            char* buf = (char*)malloc(size + 1);
            if(buf != NULL) {
                vsprintf(buf, str, args);
                buf[size] = '\n';
                xRingbufferSend(buf_handle, buf, size + 1, 1);
                free(buf);
            }
        } else {
            char temp[128];
            vsprintf(temp, str, args);
            xRingbufferSend(buf_handle, temp, size, 1);
        }
    }
    return size;
}

static void engineering_event_handler(void* event_handler_arg, esp_event_base_t event_base, 
                                        int32_t event_id, void* event_data) {
    if(event_base == BIN_EVENT_BASE) {
        if(event_id == BIN_EVENT_SAMPLES) {
            //gpio_set_level(TP47,1);
            BinEventSamples* samples = (BinEventSamples*)event_data;
            engineering_set_samples(16, samples->samples, samples->vbat_meas);
            //gpio_set_level(TP47,0);
        }
    }
}

void engineering_init() 
{
    event_register_handler(engineering_event_handler, NULL, BIN_EVENT_BASE);

    original_vprintf = esp_log_set_vprintf(engineering_vprintf);
    buf_handle = xRingbufferCreate(4096, RINGBUF_TYPE_ALLOWSPLIT);
    engr_sphr = xSemaphoreCreateBinary();
    xSemaphoreGive(engr_sphr);
}

void reboot_task(void* pvParameters )
{
    vTaskDelay(((int)pvParameters) / portTICK_PERIOD_MS);
    esp_restart();
}

void engineering_restart(int delay) 
{
    xTaskCreate(reboot_task, "REBOOT", 1024, delay, tskIDLE_PRIORITY, NULL);
}

static uint64_t device_id = 0;

void engineering_on_authenticated(uint64_t did)
{
    device_id = did;
}


uint64_t swap_long_l(uint64_t x) {
x = (x & 0x00000000FFFFFFFF) << 32 | (x & 0xFFFFFFFF00000000) >> 32;
x = (x & 0x0000FFFF0000FFFF) << 16 | (x & 0xFFFF0000FFFF0000) >> 16;
x = (x & 0x00FF00FF00FF00FF) << 8  | (x & 0xFF00FF00FF00FF00) >> 8;
return x;
}

void engineering_print_ids()
{    
    puts("=============================\n");
    if(device_id) {
        printf(" Device ID : %" PRIu64 "\n", device_id);
    } else {
        printf(" Device ID : (not assigned yet)\n");
    }
    const wifi_info_t*  wifi_info = wifi_get_info();
    if(wifi_info) {
        int64_t hton = swap_long_l(wifi_info->sn.sn);
        printf(" MAC Addr  : %" PRIX64 " \n", wifi_info->sn.sn);
        printf(" Serial No : %" PRIi64 " (%" PRIu64 ")\n", hton, wifi_info->sn.sn);
        printf(" Local IP4 : %d.%d.%d.%d\n", esp_ip4_addr1(&wifi_info->ip4), esp_ip4_addr2(&wifi_info->ip4), esp_ip4_addr3(&wifi_info->ip4), esp_ip4_addr4(&wifi_info->ip4));
    } else {
        printf(" Serial No : (not assigned yet)\n");
        printf(" Local IP4 : (not assigned yet)\n");
    }
    puts("=============================\n");
}

void engineering_logs_on()
{
    esp_log_level_set("*", ESP_LOG_INFO);
    ESP_LOGI(TAG, "Logging enabled");
}

void engineering_logs_off()
{
    esp_log_level_set("*", ESP_LOG_NONE);
}

void engineering_toggle_leds()
{
    led_set_effect(LED_EFFECT_HOLD_GREEN, 0);
}

void engineering_red_leds()
{
    led_set_effect(LED_EFFECT_HOLD_RED, 0);
}
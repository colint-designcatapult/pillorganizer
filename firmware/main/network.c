#include "network.h"
#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include <esp_http_client.h>
#include "util.h"
#include <event.h>
#include "nvs_wrapper.h"
#include "engineering.h"
#include "ota.h"
#include <nvs.h>

#include "wifi.h"
#include <esp_bt.h>
#include <string.h>

#define TAG "NETWORK"


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



#include "device_config.h"
#include <esp_mac.h>
#include <esp_log.h>
#include <string.h>
#include <sys/param.h>
#include <nvs.h>

#define TAG "devcfg"

static uint8_t s_mac[6];

void devcfg_init()
{
    // Load MAC address (for serial number)
    esp_efuse_mac_get_default(s_mac);

    char sn[SERIAL_NUMBER_STR_SIZE];
    devcfg_get_serial_number_str(sn, sizeof(sn));

    bool perm_id = devcfg_has_permanent_identity();

    char thing[128];
    bool thing_set = devcfg_get_thing_name_str(thing, sizeof(thing));

    ESP_LOGI(TAG, "Device configuration initialized");
    ESP_LOGI(TAG, "Serial number:          %s", sn);
    ESP_LOGI(TAG, "Thing name:             %s", thing_set ? thing : "(not set)");
    ESP_LOGI(TAG, "Permanent identity      %s", perm_id ? "yes" : "no");
    
}

void devcfg_get_serial_number(uint8_t sn[SERIAL_NUMBER_SIZE], size_t size)
{
    memcpy(sn, s_mac, MIN(SERIAL_NUMBER_SIZE, size));
}

void devcfg_get_serial_number_str(char serial_number[SERIAL_NUMBER_STR_SIZE], size_t size)
{
    snprintf(serial_number, size, "%02x%02x%02x%02x%02x%02x", s_mac[0], s_mac[1], s_mac[2], s_mac[3], s_mac[4], s_mac[5]);
    serial_number[SERIAL_NUMBER_STR_SIZE - 1] = '\0';
}

// Checks if all three required identity components exist in NVS
bool devcfg_has_permanent_identity(void)
{
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return false;
    }

    size_t len;
    bool has_identity = true;

    // Passing NULL to nvs_get_str queries the length. If it returns ESP_OK, the key exists.
    if (nvs_get_str(h, "DEVICE_CERT", NULL, &len) != ESP_OK) has_identity = false;
    if (nvs_get_str(h, "DEVICE_KEY", NULL, &len) != ESP_OK)  has_identity = false;
    if (nvs_get_str(h, "THING_NAME", NULL, &len) != ESP_OK)  has_identity = false;

    nvs_close(h);
    return has_identity;
}

// Retrieves the thing name into the provided buffer
bool devcfg_get_thing_name_str(char* thing_name_out, size_t size)
{
    if (!thing_name_out || size == 0) return false;

    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return false;
    }

    esp_err_t err = nvs_get_str(h, "THING_NAME", thing_name_out, &size);
    nvs_close(h);

    return (err == ESP_OK);
}

// Saves the thing name to NVS
esp_err_t devcfg_set_thing_name(const char* thing_name)
{
    if (!thing_name) return ESP_ERR_INVALID_ARG;

    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) return err;

    err = nvs_set_str(h, "THING_NAME", thing_name);
    if (err == ESP_OK) {
        err = nvs_commit(h);
    }
    
    nvs_close(h);
    return err;
}

// Saves both the certificate and private key to NVS
esp_err_t devcfg_set_permanent_cert(const char* cert, const char* privkey)
{
    if (!cert || !privkey) return ESP_ERR_INVALID_ARG;

    nvs_handle_t h;
    esp_err_t err = nvs_open("storage", NVS_READWRITE, &h);
    if (err != ESP_OK) return err;

    err = nvs_set_str(h, "DEVICE_CERT", cert);
    if (err == ESP_OK) {
        err = nvs_set_str(h, "DEVICE_KEY", privkey);
    }
    
    if (err == ESP_OK) {
        err = nvs_commit(h);
    }
    
    nvs_close(h);
    return err;
}

// Clears all identity credentials from NVS
void devcfg_reset_identity(void)
{
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READWRITE, &h) == ESP_OK) {
        nvs_erase_key(h, "DEVICE_CERT");
        nvs_erase_key(h, "DEVICE_KEY");
        nvs_erase_key(h, "THING_NAME");
        nvs_commit(h);
        nvs_close(h);
    }
}

// Retrieves the permanent certificate from NVS. 
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_cert(void)
{
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return NULL;
    }

    size_t len = 0;
    // Call with NULL first to get the required string length (including null terminator)
    if (nvs_get_str(h, "DEVICE_CERT", NULL, &len) != ESP_OK) {
        nvs_close(h);
        return NULL;
    }

    char* cert = (char*)malloc(len);
    if (!cert) {
        nvs_close(h);
        return NULL;
    }

    if (nvs_get_str(h, "DEVICE_CERT", cert, &len) != ESP_OK) {
        free(cert);
        cert = NULL;
    }

    nvs_close(h);
    return cert;
}

// Retrieves the permanent private key from NVS. 
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_key(void)
{
    nvs_handle_t h;
    if (nvs_open("storage", NVS_READONLY, &h) != ESP_OK) {
        return NULL;
    }

    size_t len = 0;
    // Call with NULL first to get the required string length (including null terminator)
    if (nvs_get_str(h, "DEVICE_KEY", NULL, &len) != ESP_OK) {
        nvs_close(h);
        return NULL;
    }

    char* key = (char*)malloc(len);
    if (!key) {
        nvs_close(h);
        return NULL;
    }

    if (nvs_get_str(h, "DEVICE_KEY", key, &len) != ESP_OK) {
        free(key);
        key = NULL;
    }

    nvs_close(h);
    return key;
}
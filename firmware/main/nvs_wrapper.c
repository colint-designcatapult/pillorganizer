#include "nvs_wrapper.h"
#include <esp_log.h>
#include <nvs.h>
#include <nvs_flash.h>
#include "esp_wifi.h"

#define STORAGE_NAMESPACE "storage"

#define TAG "nvsw"

void init_nvs()
{
    // Initialize NVS partition 
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        // NVS partition was truncated and needs to be erased 
        ESP_ERROR_CHECK(nvs_flash_erase());

        // Retry nvs_flash_init
        ESP_ERROR_CHECK(nvs_flash_init());

    }
    ESP_ERROR_CHECK(ret);
    ESP_LOGI(TAG, "NVS initialized");
}

esp_err_t nvs_write_blob(const char* key, const void* value, size_t len)
{
    nvs_handle_t h;
    esp_err_t err = nvs_open(STORAGE_NAMESPACE, NVS_READWRITE, &h);
    if (err != ESP_OK) 
        return err;

    err = nvs_set_blob(h, key, value, len);
    if (err != ESP_OK) 
        return err;
    
    err = nvs_commit(h);
    if (err != ESP_OK)
        return err;

    nvs_close(h);
    return ESP_OK;
}

esp_err_t nvs_read_blob(const char* key, void* value, size_t len)
{
    nvs_handle_t h;

    ESP_LOGI(TAG, "nvs_read_blob with key %s", key);

    esp_err_t err = nvs_open(STORAGE_NAMESPACE, NVS_READONLY, &h);
    if (err != ESP_OK) 
    {
        ESP_LOGI(TAG, "nvs_open STORAGE_NAMESPACE error %x\n", err);
        return err;
    }

    size_t reqd_size;
    err = nvs_get_blob(h, key, NULL, &reqd_size);
    if (err != ESP_OK) 
    {
        ESP_LOGI(TAG, "nvs_get_blob %s error %x\n", key, err);
        return err;
    }
    
    if(reqd_size > len)
        return ESP_ERR_INVALID_SIZE;
    
    err = nvs_get_blob(h, key, value, &len);
    if (err != ESP_OK) 
    {
        ESP_LOGI(TAG, "nvs_get_blob %s error %x\n", key, err);
        return err;
    }

    err = nvs_commit(h);
    if (err != ESP_OK)
    {
        ESP_LOGI(TAG, "nvs_commit error %x\n", err);
        return err;
    }

    nvs_close(h);
    return ESP_OK;
}

void nvs_factory_reset() {
    nvs_handle_t h;
    ESP_ERROR_CHECK(nvs_open(STORAGE_NAMESPACE, NVS_READWRITE, &h));
    ESP_ERROR_CHECK(nvs_erase_all(h));
    esp_wifi_restore();
}

esp_err_t nvs_erase_key_entry(const char* key)
{
    nvs_handle_t h;
    esp_err_t err = nvs_open(STORAGE_NAMESPACE, NVS_READWRITE, &h);
    if (err != ESP_OK) return err;

    err = nvs_erase_key(h, key);
    if (err == ESP_ERR_NVS_NOT_FOUND) {
        nvs_close(h);
        return ESP_OK;  /* already absent — not an error */
    }
    if (err != ESP_OK) {
        nvs_close(h);
        return err;
    }

    err = nvs_commit(h);
    nvs_close(h);
    return err;
}
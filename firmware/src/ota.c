#include "ota.h"
#include "config.h"
#include "network.h"
#include "engineering.h"

#include <esp_log.h>
#include <esp_ota_ops.h>
#include <esp_partition.h>
#include <esp_app_format.h>
#include <esp_http_client.h>
#include <esp_task_wdt.h>

#define TAG "OTA"
#define FIRMWARE_DOWNLOAD_PATH "/static/firmware/firmware_latest.bin"
#define DOWNLOAD_BUFFER_SIZE 32384
#define SIZE_OF_HEADER_AND_APP_REGION (sizeof(esp_image_header_t) + sizeof(esp_image_segment_header_t) + sizeof(esp_app_desc_t))
#define SIZE_OF_HEADER (sizeof(esp_image_header_t) + sizeof(esp_image_segment_header_t))
#define SIZE_OF_APP_REGION sizeof(esp_app_desc_t)

static time_t last_attempt = 0;
static SemaphoreHandle_t ota_semaphore = { 0 };

static bool ota_check_new_version(esp_app_desc_t* new_app_info) {
    ESP_LOGI(TAG, "New firmware version: %s", new_app_info->version);

    const esp_partition_t* running = esp_ota_get_running_partition();

    esp_app_desc_t running_app_info;
    if (esp_ota_get_partition_description(running, &running_app_info) == ESP_OK) {
        ESP_LOGI(TAG, "Running firmware version: %s", running_app_info.version);
    }

    const esp_partition_t* last_invalid_app = esp_ota_get_last_invalid_partition();
    esp_app_desc_t invalid_app_info;
    if (esp_ota_get_partition_description(last_invalid_app, &invalid_app_info) == ESP_OK) {
        ESP_LOGI(TAG, "Last invalid firmware version: %s", invalid_app_info.version);
    } 

    if (memcmp(running_app_info.version, new_app_info->version, sizeof(running_app_info.version)) == 0) {
        ESP_LOGW(TAG, "Refusing to update: running firmware same as downloaded");
        return false;
    }

    if (memcmp(running_app_info.version, invalid_app_info.version, sizeof(running_app_info.version)) == 0) {
        ESP_LOGW(TAG, "Refusing to update: invalid firmware same as downloaded");
        return false;
    }


    return true;
}

static bool ota_download_firmware() {
    uint8_t* ota_write_data = (uint8_t*)malloc(DOWNLOAD_BUFFER_SIZE);
    if(!ota_write_data) {
        ESP_LOGW(TAG, "Failed to allocate download buffer");
        return false;  
    }

    // Create client configuration with basic settings
    esp_http_client_config_t config = { 0 };
    network_build_base_config(&config, FIRMWARE_DOWNLOAD_PATH, HTTP_METHOD_GET);
    config.keep_alive_idle = 60;
    config.keep_alive_interval = 60;

    // Create and open HTTP client
    esp_http_client_handle_t client = esp_http_client_init(&config);
    esp_err_t err = esp_http_client_open(client, 0);
    if(err != ESP_OK)
        goto cleanup;
    int header_size = esp_http_client_fetch_headers(client);
    ESP_LOGI(TAG, "Download size %d", header_size);

    // Open update partition
    const esp_partition_t* update_partition = esp_ota_get_next_update_partition(NULL);
    esp_ota_handle_t update_handle = 0;

    // Flag to check if the incoming header has been checked yet
    bool first_read = false;

    int read_ctr = 0;

    while(true) {
        int data_read = esp_http_client_read(client, (char*)ota_write_data, DOWNLOAD_BUFFER_SIZE);
        assert(data_read <= DOWNLOAD_BUFFER_SIZE);

        ESP_LOGI(TAG, "Downloading firmware, %d/%d", read_ctr, header_size);
        read_ctr += data_read;
        if(data_read > 0) {
            // Handle data

            // Check new version to see if we already have it installed
            if(!first_read) {
                if(data_read > SIZE_OF_HEADER_AND_APP_REGION) {
                    esp_app_desc_t new_app_info;
                    memcpy(&new_app_info, &ota_write_data[SIZE_OF_HEADER], SIZE_OF_APP_REGION);
                    if(!ota_check_new_version(&new_app_info)) {
                        ESP_LOGE(TAG, "OTA version check failed");
                        err = ESP_ERR_OTA_VALIDATE_FAILED;
                        goto cleanup;
                    }
                } else {
                    ESP_LOGE(TAG, "First OTA read not big enough to read app info");
                    err = ESP_ERR_INVALID_SIZE;
                    goto cleanup;
                }
                first_read = true;
                err = esp_ota_begin(update_partition, OTA_WITH_SEQUENTIAL_WRITES, &update_handle);
                if (err != ESP_OK)
                    goto cleanup;
            }

            err = esp_ota_write(update_handle, (const void *)ota_write_data, data_read);
            if (err != ESP_OK)
                goto cleanup;

        } else if(data_read < 0) {
            // Handle error
            err = data_read;
            goto cleanup;
        } else {
            // Handle connection closed
            break;
        }
    }

    err = esp_ota_end(update_handle);
    if (err != ESP_OK) {
        if (err == ESP_ERR_OTA_VALIDATE_FAILED) {
            ESP_LOGE(TAG, "Image validation failed, image is corrupted");
        } else {
            ESP_LOGE(TAG, "esp_ota_end failed (%s)!", esp_err_to_name(err));
        }
        goto cleanup;
    }

    err = esp_ota_set_boot_partition(update_partition);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_set_boot_partition failed (%s)!", esp_err_to_name(err));
        goto cleanup;
    }

cleanup:
    esp_http_client_cleanup(client);
    free(ota_write_data);

    if(err != ESP_OK) {
        ESP_LOGE(TAG, "Error in firmware download: %x", err);
        return false;
    }

    return true;
}

static void __attribute__((noreturn)) ota_cancel_task() {
    (void)vTaskDelete(NULL);

    while (1) {
        ;
    }
}

static void ota_example_task() {
    if(xSemaphoreTake(ota_semaphore, 0) == pdTRUE) {
        if(ota_download_firmware()) {
            esp_restart();
            xSemaphoreGive(ota_semaphore);
        } else {
            xSemaphoreGive(ota_semaphore);
            ota_cancel_task();
        }
    } else {
        ESP_LOGW(TAG, "Download task already running");
        ota_cancel_task();
    }
}

static void ota_start_download_task() {
    TaskHandle_t task_handle;
    xTaskCreate(&ota_example_task, "ota_install_task", 4096, NULL, 5, &task_handle);
    //esp_task_wdt_add(task_handle);
}


void ota_handle_sync(SyncResponse* sync) {
        time_t now;
        time(&now);
        time_t timed = now - last_attempt;
        if(timed < 300) {
            ESP_LOGW(TAG, "Firmware apparently out of date, but we already tried to install it and it failed.");
        } else if(sync->latest_firmware > (FIRMWARE_REVISION)) {
            ESP_LOGI(TAG, "Firmware out of date! New revision %ld", sync->latest_firmware);
            if(!engineering_mode()) {
                ota_start_download_task();
                last_attempt = now;
            } else {
                ESP_LOGW(TAG, "Not downloading firmware update because engineering mode is enabled");
            }
        }
}

void ota_init() {
    ota_semaphore = xSemaphoreCreateBinary();
    xSemaphoreGive(ota_semaphore);
}

esp_err_t ota_start(ota_progress_t* prog) 
{
    prog->verified = false;
    prog->bytes_written = 0;
    prog->partition = esp_ota_get_next_update_partition(NULL);
    return esp_ota_begin(prog->partition, OTA_WITH_SEQUENTIAL_WRITES, &prog->handle);
}

esp_err_t ota_upload_part(ota_progress_t* prog, void* _data, size_t size)
{
    char* data = (char*)_data;
    if(!prog->verified && size > SIZE_OF_HEADER_AND_APP_REGION) {
        esp_app_desc_t new_app_info;
        memcpy(&new_app_info, &data[SIZE_OF_HEADER], SIZE_OF_APP_REGION);
        if(!ota_check_new_version(&new_app_info)) {
            ESP_LOGE(TAG, "OTA version check failed");
            return ESP_ERR_OTA_VALIDATE_FAILED;
        } else {
            prog->verified = true;
        }
    }
    prog->bytes_written += size;
    return esp_ota_write(prog->handle, data, size);
}

esp_err_t ota_cancel(ota_progress_t* prog)
{
    return esp_ota_abort(prog->handle);
}

esp_err_t ota_finish(ota_progress_t* prog)
{
    esp_err_t err;
    if((err = esp_ota_end(prog->handle)) == ESP_OK) {
        esp_ota_set_boot_partition(prog->partition);
    }
    return err;
}
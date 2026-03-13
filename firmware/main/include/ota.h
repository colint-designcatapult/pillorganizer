#pragma once
#include <esp_partition.h>
#include <esp_ota_ops.h>

void ota_init();


typedef struct _ota_progress_t {
    bool verified;
    size_t bytes_written;
    const esp_partition_t* partition;
    esp_ota_handle_t handle;
} ota_progress_t;

esp_err_t ota_start(ota_progress_t* prog);
esp_err_t ota_upload_part(ota_progress_t* prog, void* data, size_t size);
esp_err_t ota_cancel(ota_progress_t* prog);
esp_err_t ota_finish(ota_progress_t* prog);
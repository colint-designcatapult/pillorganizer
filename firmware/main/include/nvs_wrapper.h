#pragma once

#include <esp_err.h>
#include <nvs.h>


void init_nvs();

esp_err_t nvs_write_blob(const char* key, const void* value, size_t len);
esp_err_t nvs_read_blob(const char* key, void* value, size_t len);

void nvs_factory_reset();

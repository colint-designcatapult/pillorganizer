#pragma once

#include <esp_err.h>
#include <nvs.h>


void init_nvs();

esp_err_t nvs_write_blob(const char* key, const void* value, size_t len);
esp_err_t nvs_read_blob(const char* key, void* value, size_t len);

/* Erase a single NVS key. Returns ESP_OK if the key did not exist. */
esp_err_t nvs_erase_key_entry(const char* key);

void nvs_factory_reset();

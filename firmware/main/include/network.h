#pragma once

#include <freertos/FreeRTOS.h>
#include <freertos/message_buffer.h>
#include <esp_http_client.h>


#ifdef __cplusplus
extern "C" {
#endif

void network_init();
void network_build_base_config(esp_http_client_config_t* config, const char* path,
     esp_http_client_method_t method);

// Provisioning helpers
esp_err_t network_set_certificate(const uint8_t* cert, size_t len);
void network_get_serial_number(uint8_t* sn_out, size_t* len_out);

// Fleet Provisioning certificate storage
esp_err_t network_save_cert_to_nvs(const char* nvs_key, const char* cert_pem);
esp_err_t network_load_cert_from_nvs(const char* nvs_key, char** cert_out, size_t* len_out);
esp_err_t network_save_thing_name(const char* thing_name);
esp_err_t network_load_thing_name(char* thing_name_out, size_t max_len);

#ifdef __cplusplus
}
#endif
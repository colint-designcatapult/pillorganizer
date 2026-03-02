#pragma once

#include "pill_state.h"
#include <freertos/FreeRTOS.h>
#include <freertos/message_buffer.h>
#include <esp_http_client.h>

#include "pill.pb.h"

#ifdef __cplusplus
extern "C" {
#endif

void network_init();
void network_build_base_config(esp_http_client_config_t* config, const char* path,
     esp_http_client_method_t method);

// Provisioning helpers
esp_err_t network_set_certificate(const uint8_t* cert, size_t len);
void network_get_serial_number(uint8_t* sn_out, size_t* len_out);

#ifdef __cplusplus
}
#endif
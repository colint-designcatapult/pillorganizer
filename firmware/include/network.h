#pragma once

#include "pill_state.h"
#include <freertos/FreeRTOS.h>
#include <freertos/message_buffer.h>
#include <esp_http_client.h>

#include "pill.pb.h"



void network_init();
esp_err_t network_set_oob_key(const uint8_t* key, size_t len);
esp_err_t network_set_server_url(const uint8_t* pServerUrl, size_t len);
void network_build_base_config(esp_http_client_config_t* config, const char* path,
     esp_http_client_method_t method);
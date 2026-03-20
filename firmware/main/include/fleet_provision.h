#pragma once
#include <esp_err.h>

esp_err_t fleet_provision_start(const char* claim_cert_pem, const char* claim_key_pem,
                                     const char* claim_id, const char* claim_token);
void fleet_provision_deinit();
/* 
 * Device Configuration
 * 
 */
#pragma once
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <esp_err.h>

#define SERIAL_NUMBER_SIZE 6
#define SERIAL_NUMBER_STR_SIZE 13

void devcfg_init();
void devcfg_get_serial_number(uint8_t sn[SERIAL_NUMBER_SIZE], size_t size);
void devcfg_get_serial_number_str(char serial_number[SERIAL_NUMBER_STR_SIZE], size_t size);

bool devcfg_has_permanent_identity();
void devcfg_reset_identity();

bool devcfg_get_thing_name_str(char* thing_name_out, size_t size);
esp_err_t devcfg_set_thing_name(const char* thing_name);

// Retrieves the permanent private key from NVS. 
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_key();

// Retrieves the permanent certificate from NVS. 
// NOTE: The caller must free() the returned pointer when done.
const char* devcfg_get_permanent_cert();

esp_err_t devcfg_set_permanent_cert(const char* cert, const char* privkey);



/* 
 * Wi-Fi Provision Manager
 * 
 */
#pragma once
#include <stdbool.h>

bool wifiprov_is_provisioned();
void wifiprov_start_provision();
void wifiprov_reset_provision();
void wifiprov_deinit();
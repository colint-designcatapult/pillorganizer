#pragma once
#include <stdbool.h>
#include "pill_types.h"


bool engineering_mode();
uint32_t engineering_get_bin_voltage(int bin_id);
void engineering_print_samples();
void engineering_init();
void engineering_start_server();
void engineering_stop_server();
void engineering_on_authenticated(uint64_t device_id);
void engineering_print_ids();
void engineering_logs_on();
void engineering_logs_off();
void engineering_toggle_leds();
void engineering_red_leds();

void engineering_restart(int delay);

extern bool telemetry_heartbeat_active;

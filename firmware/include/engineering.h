#pragma once
#include <stdbool.h>
#include "pill.pb.h"
#include "pill_types.h"


bool engineering_mode();
void engineering_handle_sync(SyncResponse* sync);
EngineeringRequest* engineering_request();
void engineering_print_samples();
void engineering_build_sync(SyncRequest* sync);
void engineering_init();
void engineering_start_server();
void engineering_stop_server();
void engineering_on_authenticated(uint64_t device_id);
void engineering_print_ids();
void engineering_logs_on();
void engineering_logs_off();

void engineering_restart(int delay);

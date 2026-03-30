#pragma once
#include "supervisor.h"

void supervisor_operation_init();
void supervisor_operation_event(const supervisor_event_t* event);
void supervisor_operation_tick();

esp_err_t supervisor_operation_get_schedule(device_schedule_t* sched);
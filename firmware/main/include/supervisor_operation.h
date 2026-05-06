#pragma once
#include "supervisor.h"

void supervisor_operation_init();
void supervisor_operation_event(const supervisor_event_t* event);
void supervisor_operation_tick();

esp_err_t supervisor_operation_get_schedule(device_schedule_t* sched);
esp_err_t supervisor_operation_trigger_reload(void);

#if CONFIG_FIRMWARE_ENGINEERING
esp_err_t supervisor_operation_reset_pending_bins(void);
#endif // CONFIG_FIRMWARE_ENGINEERING
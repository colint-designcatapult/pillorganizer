#pragma once
#include "supervisor.h"

/**
 * Initializes the OTA supervisor. Sets all LEDs solid red to indicate OTA mode.
 * @return true  if a pending OTA job was found in NVS and OTA mode should run
 *         false if there is no pending job
 */
bool supervisor_ota_init(void);

void supervisor_ota_event(const supervisor_event_t* event);
void supervisor_ota_tick(void);

#pragma once
#include "supervisor.h"

/**
 * Initializes the provisioning supervisor.
 * @return true if the device needs provisioning
 *         false if the device is ready (fully provisioned)
 */
bool supervisor_provision_init();
void supervisor_provision_event(const supervisor_event_t* event);
void supervisor_provision_tick();
/*
 * Device Claim & Fleet Provisioning Subsystem
 *
 */
#pragma once
#include <stdbool.h>

void claim_init();
bool claim_has_credentials();
void claim_set_credentials(const char* claim_id, const char* claim_token);
void claim_execute_fetch();
void claim_fleet_provision();
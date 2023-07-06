#pragma once
#include "pill_types.h"
#include <stdint.h>
#include <time.h>

void state_init();
void state_set_bin_bitmask(uint16_t bitmask);
bin_status_t state_get_bin_status(bin_id_t bin);
void state_rebuild_schedule(bool next_week);

void state_set_state(AllBinsState* abs);
void state_set_schedule(BinSchedule* schedules, size_t schedule_count);
void state_build_sync_request(SyncRequest* req);

bool state_is_flashing_reload();

const bin_state_t* state_acquire_ro();
void state_release_ro(const bin_state_t*);

temp_state_t* state_temp();

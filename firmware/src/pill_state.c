#include "pill_state.h"
#include <stdio.h>
#include <esp_log.h>
#include <memory.h>
#include <time.h>
#include "nvs_wrapper.h"
#include <nvs.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "read_write_lock.h"
#include "event.h"
#include <esp_crc.h>
#include "util.h"

#define TAG "STATE"

#define MISSED_DOSE_THRESHOLD 600

typedef BinSchedule bin_schedule_t;

typedef struct _bin_sorted {
    bin_id_t bin;
    time_t schedule_time;
} bin_sorted_t;

typedef struct _persisted_state {
    bool            has_state;
    bin_state_t     bin_state[BIN_COUNT];
    bin_schedule_t  bin_schedule[BIN_COUNT];
    bin_id_t        first_seq_bin;
    bin_id_t        last_seq_bin;
} persisted_state_t;

persisted_state_t _pers                 = { 0 };
ReadWriteLock_t*  _pers_lock            = NULL;
temp_state_t      temp_state[BIN_COUNT] = { 0 };


static const persisted_state_t* state_acquire()
{
    ReaderLock(_pers_lock);
    return &_pers;
}

static persisted_state_t* state_acquire_writer()
{
    WriterLock(_pers_lock);
    return &_pers;
}


static void state_release(const persisted_state_t* pers)
{
    ReaderUnlock(_pers_lock);
}

const bin_state_t* state_acquire_ro() {
    ReaderLock(_pers_lock);
    return (const bin_state_t*)&_pers.bin_state;
}

void state_release_ro(const bin_state_t* st) {
    ReaderUnlock(_pers_lock);
}

static void _persist_state()
{
    ESP_ERROR_CHECK(nvs_write_blob("PERSISTED_STATE", &_pers, sizeof(persisted_state_t)));
}

static void state_release_writer_no_persist(persisted_state_t* pers)
{
    WriterUnlock(_pers_lock);
}

static void state_release_writer(persisted_state_t* pers)
{
    _persist_state();
    state_release_writer_no_persist(pers);
}



void update_bin_status(persisted_state_t* pers, bin_id_t bin, bin_status_t status)
{
    pers->bin_state[bin].status = status;
    ESP_LOGI(TAG, "Bin %d moved to status %d", bin, status);
}



void fire_bin_event_dispense(bin_id_t bin, time_t open, time_t close)
{
    persisted_state_t* pers = state_acquire_writer();

    bin_state_t* current_state = &pers->bin_state[bin];
    bin_status_t current_status = current_state->status;

    ESP_LOGI(TAG, "dispense event");

    if(current_status == BIN_TAKE_NOW) {
        update_bin_status(pers, bin, BIN_TAKEN);
    } else if(current_status == BIN_PENDING || current_status == BIN_MISSED) {        


        if(current_state->next_bin != BIN_NULL && current_state->prev_bin != BIN_NULL 
                && (close < pers->bin_state[current_state->next_bin].schedule_time
                && close > pers->bin_state[current_state->prev_bin].schedule_time)) {
            update_bin_status(pers, bin, BIN_TAKEN);
        } else if(current_state->next_bin != BIN_NULL 
                && (close > pers->bin_state[current_state->prev_bin].schedule_time)) {

            update_bin_status(pers, bin, BIN_TAKEN);
        } else if(current_state->prev_bin != BIN_NULL
                && (close > pers->bin_state[current_state->prev_bin].schedule_time)) {

            update_bin_status(pers, bin, BIN_TAKEN);
        }
    }
    state_release_writer(pers);
    // suppress open events (unneeded)
    on_bin_event(bin, BIN_EVENT_CLOSED, close);
}

static void record_bin_event_missed(persisted_state_t* pers, bin_id_t bin, time_t declared_missed)
{
    update_bin_status(pers, bin, BIN_MISSED);
    on_bin_event(bin, BIN_EVENT_MISSED, declared_missed);
    ESP_LOGI(TAG, "Bin %d marked as missed", bin);
}

void state_task()
{
    while(true) {    
        time_t now;
        time(&now);

        persisted_state_t* pers = state_acquire_writer();

        // Check to see if any bins are scheduled to be opened and detect missed doses
        for(bin_id_t bin = 0; bin < BIN_COUNT; bin++) {
            bin_state_t* state = &pers->bin_state[bin];
            bin_status_t status = state->status;
            time_t delta_time = now - state->schedule_time;

            if (status == BIN_PENDING) {
                if(delta_time >= 0 && delta_time <= MISSED_DOSE_THRESHOLD) {
                    update_bin_status(pers, bin, BIN_TAKE_NOW);
                }
            }

            if(status == BIN_TAKE_NOW) {
                if(delta_time > MISSED_DOSE_THRESHOLD) {
                    // This dose is now missed
                    record_bin_event_missed(pers, bin, now);
                }
            }
        }
        state_release_writer(pers);

        vTaskDelay(500 / portTICK_PERIOD_MS);

       // esp_task_wdt_reset();
    }
}

void state_event_handler(void* event_handler_arg, esp_event_base_t event_base,
                            int32_t event_id, void* event_data) {
    if(event_base == BIN_EVENT_BASE) {
        if(event_id == BIN_EVENT_BITMASK_CHANGED) {
            BinEventBitmaskChanged* changed = (BinEventBitmaskChanged*)event_data;
            state_set_bin_bitmask(changed->bitmask);
        }
    }
}


void state_init()
{
    _pers_lock = CreateReadWriteLockPreferReader();

    esp_err_t err = nvs_read_blob("PERSISTED_STATE", &_pers, sizeof(persisted_state_t));
    if(ESP_OK != err) {
        // bin state not persisted yet, initialize to zero & persist
        memset(&_pers, 0, sizeof(persisted_state_t));
        _persist_state();
    }

    event_register_handler(state_event_handler, NULL, BIN_EVENT_BASE);

    // Create state task
    xTaskCreate(&state_task, "State Task", 4096, NULL, 2, NULL);
}

void on_bin_open_raw(bin_id_t bin)
{
    temp_state_t* state = &temp_state[bin];
    if(!state->open) {

        time_t t;
        time(&t);

        ESP_LOGI(TAG, "Bin %d OPENED", bin);

        state->open = true;
        state->time_reg = t;
    }
}

void on_bin_close_raw(bin_id_t bin)
{
    temp_state_t* state = &temp_state[bin];
    if(state->open) {
        time_t t;
        time(&t);

        state->open = false;
        time_t close = t, open = state->time_reg;

        ESP_LOGI(TAG, "Bin %d CLOSED", bin);

        // Bin must be open for at least 2 seconds for it to be considered a dispense event
        if(close - open >= 2)
            fire_bin_event_dispense(bin, open, close);
    }
}

/* 
    MSB                                                              LSB
    SUN  SUN  SAT  SAT  FRI  FRI  THU  THU  WED  WED  TUE  TUE  MON  MON 
    AM   PM   AM   PM   AM   PM   AM   PM   AM   PM   AM   PM   AM   PM
*/
uint16_t bin_mask = 0;
void state_set_bin_bitmask(uint16_t new_mask)
{
    new_mask &= 0x3FFF;
    if(new_mask != bin_mask) {
        for(bin_id_t i = 0; i < BIN_COUNT; i++) {
            uint16_t bin_flag = 1 << i;
            if((bin_mask & bin_flag) == bin_flag && (new_mask & bin_flag) != bin_flag) {
                on_bin_close_raw(i);
            } else if((bin_mask & bin_flag) != bin_flag && (new_mask & bin_flag) == bin_flag) {
                on_bin_open_raw(i);
            }
        }
        bin_mask = new_mask; 
    }
}


void update_schedule(time_t timestamps[BIN_COUNT])
{
    persisted_state_t* pers_rw = state_acquire_writer();
    for(bin_id_t id = 0; id < BIN_COUNT; id++) {
        pers_rw->bin_state[id].schedule_time = timestamps[id];
    }
    state_release_writer(pers_rw);
}

time_t calculate_offset_from_start_of_week(struct tm* start_of_week, BinSchedule_DayOfWeek dow, int seconds)
{
    struct tm tm = *start_of_week;
    int day_offset = 0;
    switch(dow) {
        case BinSchedule_DayOfWeek_MONDAY:
            day_offset = 0;
            break;
        case BinSchedule_DayOfWeek_TUESDAY:
            day_offset = 1;
            break;
        case BinSchedule_DayOfWeek_WEDNESDAY:
            day_offset = 2;
            break;
        case BinSchedule_DayOfWeek_THURSDAY:
            day_offset = 3;
            break;
        case BinSchedule_DayOfWeek_FRIDAY:
            day_offset = 4;
            break;
        case BinSchedule_DayOfWeek_SATURDAY:
            day_offset = 5;
            break;
        case BinSchedule_DayOfWeek_SUNDAY:
            day_offset = 6;
            break;
        default:
            break;

    }
    tm.tm_mday += day_offset;
    tm.tm_hour = 0;
    tm.tm_min = 0;
    tm.tm_sec = seconds;
    return mktime(&tm);
}

static int compare_sorted_bins(const void * c1, const void * c2) {
    const bin_sorted_t* b1 = (bin_sorted_t*)c1, *b2 = (bin_sorted_t*)c2;
    return b1->schedule_time - b2->schedule_time;
}

static void state_recalculate_order(persisted_state_t* pers_rw) 
{
    bin_sorted_t bin_ordered[BIN_COUNT];

    // Go through each bin and identify which bins are sequentially previous and next
    for(bin_id_t bin = 0; bin < BIN_COUNT; bin++) {
        bin_ordered[bin].bin            = bin;
        bin_ordered[bin].schedule_time  = pers_rw->bin_state[bin].schedule_time;
    }

    // Sort the array
    qsort(bin_ordered, BIN_COUNT, sizeof(bin_sorted_t), compare_sorted_bins);

    for(bin_id_t bin = 0; bin < BIN_COUNT; bin++) {
        bin_sorted_t* sorted = &bin_ordered[bin];
        bin_state_t* state = &pers_rw->bin_state[sorted->bin];
        if(bin > 0) {
            state->prev_bin = bin - 1;
        } else {
            state->prev_bin = BIN_NULL;
            pers_rw->first_seq_bin = bin;
        }

        if(bin < BIN_COUNT - 1) {
            state->next_bin = bin + 1;
        } else {
            state->next_bin = BIN_NULL;
            pers_rw->last_seq_bin = bin;
        }
    }

}

void state_rebuild_schedule(bool new_week)
{
    time_t now;
    time(&now);
    struct tm* now_gm = gmtime(&now);

    struct tm tm = { 0 };
    tm.tm_mday  = now_gm->tm_mday - (now_gm->tm_wday) + 1;
    tm.tm_mon   = now_gm->tm_mon;
    tm.tm_year  = now_gm->tm_year;
    tm.tm_isdst = now_gm->tm_isdst;

    persisted_state_t* pers_rw = state_acquire_writer();

    // Go through each bin and see if it needs the scheduled time reconfigured
    for(bin_id_t bin = 0; bin < BIN_COUNT; bin++) {
        bin_state_t* st = &pers_rw->bin_state[bin];
        bin_schedule_t* sch = &pers_rw->bin_schedule[bin];
        if(sch->day_of_week != BinSchedule_DayOfWeek_DISABLED) {
            if(new_week || (st->status != BIN_TAKEN && st->status != BIN_MISSED)) {
                time_t offset = calculate_offset_from_start_of_week(&tm, sch->day_of_week, sch->seconds_from_00);
                char strftime_buf[64];
                strftime(strftime_buf, sizeof(strftime_buf), "%c", gmtime(&offset));
                ESP_LOGI(TAG, "Bin %d scheduled for %s", bin, strftime_buf);

                st->schedule_time = offset;

                if(offset > (now - MISSED_DOSE_THRESHOLD)) {
                    st->status = BIN_PENDING;
                } else {
                    // Disable this bin, schedule was updated with this bin scheduled to be taken already
                    st->status = BIN_DISABLED;
                }
            }
        } else {
            st->status = BIN_DISABLED;
            st->schedule_time = 0;
        }
    }

    state_recalculate_order(pers_rw);
    state_release_writer(pers_rw);
}

void state_set_state(AllBinsState* abs)
{
    persisted_state_t* pers_rw = state_acquire_writer();
    for(bin_id_t bin = 0; bin < abs->bins_count; bin++) {
        BinState* bs = &abs->bins[bin];
        bin_state_t* our_bs = &pers_rw->bin_state[bin];

        if(our_bs->status != (bin_status_t)bs->status) {
            our_bs->status = (bin_status_t)bs->status;
            ESP_LOGI(TAG, "Bin %d assigned state %d at time %d", bin, bs->status, (int)our_bs->schedule_time);
        }
        our_bs->schedule_time = (time_t)(bs->scheduled_time);
    }
    state_release_writer(pers_rw);
    state_recalculate_order(pers_rw);
}

void state_set_schedule(BinSchedule* schedules, size_t schedule_count)
{
    persisted_state_t* pers_rw = state_acquire_writer();

    bool modified = false;
    for(bin_id_t bin = 0; bin < schedule_count; bin++) {
        BinSchedule* sched = &schedules[bin];
        bin_schedule_t* orig_sched = &pers_rw->bin_schedule[bin];

        // Only update schedule if we really have to
        if(sched->day_of_week != orig_sched->day_of_week || sched->seconds_from_00 != orig_sched->seconds_from_00) {
            orig_sched->day_of_week         = sched->day_of_week;
            orig_sched->seconds_from_00     = sched->seconds_from_00;
            modified = true;
        }
    }

    if(modified) {
        ESP_LOGI(TAG, "Bin schedule change detected, rebuilding state");
        state_release_writer(pers_rw);
        state_rebuild_schedule(false);
    } else {
        state_release_writer_no_persist(pers_rw);
    }
}

temp_state_t* state_temp()
{
    return temp_state;
}


void state_build_sync_request(SyncRequest* req)
{
    const persisted_state_t* pers = state_acquire();

    req->bin_state.bins_count = BIN_COUNT;
    req->has_bin_state = true;

    uint32_t crc = 0;
    for(bin_id_t bin = 0; bin < BIN_COUNT; bin++) {
        bin_state_t* bs = &pers->bin_state[bin];

        struct {
            uint8_t status;
            int64_t time;
        } __attribute__((packed)) s = {
            .status = bs->status,
            .time = bs->schedule_time
        };

        uint8_t* bytes = (uint8_t*)&s;
        crc = esp_crc32_le(crc, bytes, sizeof(s));

        BinState* w = &req->bin_state.bins[bin];
        w->scheduled_time = bs->schedule_time;
        w->status = bs->status;
    }
    req->state_hash = crc;

    state_release_ro(pers);
}
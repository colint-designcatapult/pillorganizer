#include "event_outbox.h"
#include "nvs_wrapper.h"
#include <string.h>
#include <inttypes.h>
#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

#define TAG "EVENT_OUTBOX"

#define EVENT_OUTBOX_NVS_KEY    "evt_outbox"
#define EVENT_OUTBOX_MAGIC      0xA5B6C7D8u
#define EVENT_OUTBOX_PERSIST_MS (60LL * 1000LL)

/* ------------------------------------------------------------------ */
/*  RTC-backed state                                                    */
/* ------------------------------------------------------------------ */

typedef struct {
    event_outbox_entry_t entries[EVENT_OUTBOX_MAX_ENTRIES];
    int      head;      /* physical slot of the oldest valid entry */
    int      count;     /* number of valid entries                 */
} event_outbox_queue_t;

static RTC_DATA_ATTR uint32_t             s_magic;
static RTC_DATA_ATTR event_outbox_queue_t s_queue;
static RTC_DATA_ATTR uint32_t             s_next_seq;  /* monotonic counter    */
/* Relative timestamp of the first push that produced an unpersisted entry.
 * 0 = nothing to persist. */
static RTC_DATA_ATTR rtc_relative_time_t  s_dirty_since;

/* Connection epoch – incremented on every reset_inflight (MQTT disconnect).
 * Lives in DRAM: resets to 0 on cold boot is fine because all entry msg_ids
 * are also reset to -1 on init, so there can be no epoch mismatch.
 * uint64_t ensures the counter never wraps in practice. */
static uint64_t s_conn_epoch = 0;

/* Mutex lives in normal DRAM – recreated on every boot. */
static SemaphoreHandle_t s_mutex = NULL;

/* ------------------------------------------------------------------ */
/*  Internal helpers (called with mutex already held)                  */
/* ------------------------------------------------------------------ */

static void save_to_nvs_locked(void)
{
    esp_err_t err = nvs_write_blob(EVENT_OUTBOX_NVS_KEY, &s_queue, sizeof(s_queue));
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "NVS write failed: 0x%x", err);
        return;
    }
    for (int i = 0; i < EVENT_OUTBOX_MAX_ENTRIES; i++) {
        if (s_queue.entries[i].valid) {
            s_queue.entries[i].persisted = true;
        }
    }
    s_dirty_since = 0;
    ESP_LOGI(TAG, "Outbox persisted to NVS (%d entries)", s_queue.count);
}

static void update_nvs_after_pop_locked(void)
{
    esp_err_t err = nvs_write_blob(EVENT_OUTBOX_NVS_KEY, &s_queue, sizeof(s_queue));
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "NVS update after pop failed: 0x%x", err);
    } else {
        ESP_LOGD(TAG, "NVS updated after pop (%d remaining)", s_queue.count);
    }
}

/* Set s_dirty_since to 0 when no unpersisted entries remain. */
static void refresh_dirty_state_locked(void)
{
    if (s_dirty_since == 0) return;
    for (int i = 0; i < s_queue.count; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        if (s_queue.entries[idx].valid && !s_queue.entries[idx].persisted) {
            return; /* still dirty */
        }
    }
    s_dirty_since = 0;
}

/*
 * Pop a single front entry that is known to be delivered.
 * Caller must hold the mutex.
 */
static void pop_front_locked(void)
{
    bool was_persisted = s_queue.entries[s_queue.head].persisted;
    memset(&s_queue.entries[s_queue.head], 0, sizeof(event_outbox_entry_t));
    s_queue.head  = (s_queue.head + 1) % EVENT_OUTBOX_MAX_ENTRIES;
    s_queue.count--;
    if (was_persisted) {
        update_nvs_after_pop_locked();
    }
}

/* Reset msg_id on every undelivered entry and advance the connection epoch.
 * Caller is responsible for locking: either hold s_mutex, or call before
 * the FreeRTOS scheduler starts (e.g. from event_outbox_init). */
static void reset_inflight_nolock(void)
{
    s_conn_epoch++;
    for (int i = 0; i < s_queue.count; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        if (s_queue.entries[idx].valid && !s_queue.entries[idx].delivered) {
            s_queue.entries[idx].msg_id = -1;
        }
    }
}

/* ------------------------------------------------------------------ */
/*  Public API                                                          */
/* ------------------------------------------------------------------ */

void event_outbox_init(void)
{
    s_mutex = xSemaphoreCreateMutex();
    configASSERT(s_mutex != NULL);

    if (s_magic == EVENT_OUTBOX_MAGIC) {
        /* s_magic matches, so the RTC domain was powered during deep sleep.
         * Still validate head/count: a brownout could corrupt those fields
         * while leaving the magic word intact. */
        bool rtc_valid = (s_queue.count >= 0 &&
                          s_queue.count <= EVENT_OUTBOX_MAX_ENTRIES &&
                          s_queue.head  >= 0 &&
                          s_queue.head  <  EVENT_OUTBOX_MAX_ENTRIES);
        if (rtc_valid) {
            ESP_LOGI(TAG, "Restored from RTC memory (%d entries)", s_queue.count);
            /* MQTT has disconnected since last wake, so any in-flight
             * msg_ids are stale and must be cleared.
             * Called before tasks start so no mutex is needed. */
            reset_inflight_nolock();
            return;
        }
        ESP_LOGW(TAG, "RTC outbox state invalid (head=%d count=%d), reinitialising",
                 s_queue.head, s_queue.count);
        /* Fall through to cold-boot initialisation and attempt NVS restore. */
    }

    /* Cold boot: initialise RTC state then attempt NVS restore. */
    memset(&s_queue, 0, sizeof(s_queue));
    s_dirty_since = 0;
    s_next_seq    = 0;
    s_magic       = EVENT_OUTBOX_MAGIC;

    event_outbox_queue_t nvs_queue;
    memset(&nvs_queue, 0, sizeof(nvs_queue));

    esp_err_t err = nvs_read_blob(EVENT_OUTBOX_NVS_KEY, &nvs_queue, sizeof(nvs_queue));
    if (err == ESP_OK) {
        if (nvs_queue.count >= 0 &&
            nvs_queue.count <= EVENT_OUTBOX_MAX_ENTRIES &&
            nvs_queue.head  >= 0 &&
            nvs_queue.head  <  EVENT_OUTBOX_MAX_ENTRIES) {

            memcpy(&s_queue, &nvs_queue, sizeof(s_queue));

            /* Restore all loaded entries: they are in NVS, not in-flight. */
            for (int i = 0; i < EVENT_OUTBOX_MAX_ENTRIES; i++) {
                if (s_queue.entries[i].valid) {
                    s_queue.entries[i].persisted = true;
                    s_queue.entries[i].msg_id    = -1;
                    s_queue.entries[i].delivered = false;
                    /* Advance s_next_seq past all restored sequence numbers. */
                    if (s_queue.entries[i].seq >= s_next_seq) {
                        s_next_seq = s_queue.entries[i].seq + 1;
                    }
                }
            }
            ESP_LOGI(TAG, "Restored %d events from NVS (next_seq=%" PRIu32 ")",
                     s_queue.count, s_next_seq);
        } else {
            ESP_LOGW(TAG, "NVS outbox data corrupted, discarding");
        }
    } else if (err == ESP_ERR_NVS_NOT_FOUND) {
        ESP_LOGI(TAG, "No outbox data in NVS");
    } else {
        ESP_LOGW(TAG, "NVS read error: 0x%x", err);
    }
}

esp_err_t event_outbox_push(rtc_utc_timestamp_ms timestamp,
                             device_event_type_t event_type,
                             int bin_id,
                             int flags)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);

    if (s_queue.count >= EVENT_OUTBOX_MAX_ENTRIES) {
        xSemaphoreGive(s_mutex);
        ESP_LOGE(TAG, "Outbox full!");
        return ESP_ERR_NO_MEM;
    }

    int tail = (s_queue.head + s_queue.count) % EVENT_OUTBOX_MAX_ENTRIES;
    event_outbox_entry_t *e = &s_queue.entries[tail];
    e->timestamp  = timestamp;
    e->event_type = event_type;
    e->bin_id     = bin_id;
    e->flags      = flags;
    e->seq        = s_next_seq++;
    e->msg_id     = -1;
    e->delivered  = false;
    e->valid      = true;
    e->persisted  = false;

    s_queue.count++;

    if (s_dirty_since == 0) {
        s_dirty_since = app_rtc_get_relative_timestamp();
    }

    ESP_LOGD(TAG, "Pushed seq=%" PRIu32 " type=%d bin=%d count=%d",
             e->seq, event_type, bin_id, s_queue.count);

    xSemaphoreGive(s_mutex);
    return ESP_OK;
}

esp_err_t event_outbox_get(int pos, event_outbox_entry_t *out_entry)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);

    if (pos < 0 || pos >= s_queue.count) {
        xSemaphoreGive(s_mutex);
        return ESP_ERR_NOT_FOUND;
    }

    int idx = (s_queue.head + pos) % EVENT_OUTBOX_MAX_ENTRIES;
    *out_entry = s_queue.entries[idx];

    xSemaphoreGive(s_mutex);
    return ESP_OK;
}

uint64_t event_outbox_get_conn_epoch(void)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    uint64_t epoch = s_conn_epoch;
    xSemaphoreGive(s_mutex);
    return epoch;
}

esp_err_t event_outbox_set_msg_id(uint32_t seq, int msg_id, uint64_t conn_epoch)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);

    /* If the epoch has advanced, a disconnect fired between the publish
     * call and this write.  The entry's msg_id was already reset to -1 by
     * reset_inflight; writing the now-stale id would make the entry look
     * in-flight and block future delivery. */
    if (s_conn_epoch != conn_epoch) {
        xSemaphoreGive(s_mutex);
        return ESP_ERR_INVALID_STATE;
    }

    for (int i = 0; i < s_queue.count; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        if (s_queue.entries[idx].valid && s_queue.entries[idx].seq == seq) {
            s_queue.entries[idx].msg_id = msg_id;
            xSemaphoreGive(s_mutex);
            return ESP_OK;
        }
    }

    xSemaphoreGive(s_mutex);
    return ESP_ERR_NOT_FOUND;
}

esp_err_t event_outbox_ack(int msg_id)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);

    /* Find the entry with this msg_id and mark it delivered. */
    bool found = false;
    for (int i = 0; i < s_queue.count; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        if (s_queue.entries[idx].valid && s_queue.entries[idx].msg_id == msg_id) {
            s_queue.entries[idx].delivered = true;
            found = true;
            ESP_LOGD(TAG, "ACK seq=%" PRIu32 " msg_id=%d", s_queue.entries[idx].seq, msg_id);
            break;
        }
    }

    if (!found) {
        xSemaphoreGive(s_mutex);
        return ESP_ERR_NOT_FOUND;
    }

    /* Pop all consecutive delivered entries from the front. */
    while (s_queue.count > 0 && s_queue.entries[s_queue.head].delivered) {
        ESP_LOGD(TAG, "Popping seq=%" PRIu32 ", remaining=%d",
                 s_queue.entries[s_queue.head].seq, s_queue.count - 1);
        pop_front_locked();
    }

    refresh_dirty_state_locked();

    xSemaphoreGive(s_mutex);
    return ESP_OK;
}

void event_outbox_reset_inflight(void)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    reset_inflight_nolock();
    xSemaphoreGive(s_mutex);
}

int event_outbox_count(void)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);
    int count = s_queue.count;
    xSemaphoreGive(s_mutex);
    return count;
}

bool event_outbox_is_full(void)
{
    return event_outbox_count() >= EVENT_OUTBOX_MAX_ENTRIES;
}

void event_outbox_tick(void)
{
    xSemaphoreTake(s_mutex, portMAX_DELAY);

    if (s_dirty_since == 0 || s_queue.count == 0) {
        xSemaphoreGive(s_mutex);
        return;
    }

    rtc_relative_time_t now = app_rtc_get_relative_timestamp();
    int64_t             age = app_rtc_calc_duration_ms(s_dirty_since, now);

    if (age >= EVENT_OUTBOX_PERSIST_MS) {
        ESP_LOGI(TAG, "Persisting outbox after %lld ms", age);
        save_to_nvs_locked();
    }

    xSemaphoreGive(s_mutex);
}


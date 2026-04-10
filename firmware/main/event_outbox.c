#include "event_outbox.h"
#include "mqtt.h"
#include "nvs_wrapper.h"
#include <string.h>
#include <inttypes.h>
#include <esp_log.h>

#define TAG "EVENT_OUTBOX"

#define EVENT_OUTBOX_NVS_KEY    "evt_outbox"
#define EVENT_OUTBOX_MAGIC      0xA5B6C7D8u
#define EVENT_OUTBOX_PERSIST_MS (60LL * 1000LL)
/* After this many ms of seeing entries stuck in-flight (msg_id >= 0 but
 * not delivered), reset all in-flight msg_ids so drain can republish them.
 * This recovers from dropped PUBACK events (e.g. supervisor queue full). */
#define EVENT_OUTBOX_INFLIGHT_TIMEOUT_MS (30LL * 1000LL)
/* Maximum entries published per drain call.  Keeping this well below the
 * supervisor queue size (16) prevents the resulting PUBACK events from
 * overflowing the queue. */
#define EVENT_OUTBOX_DRAIN_MAX_PER_CALL 6

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

/* Relative timestamp of when we first noticed entries stuck in-flight.
 * 0 = no stuck entries currently known.  Lives in DRAM (not RTC): reset on
 * every boot is safe since a boot also resets all msg_ids. */
static rtc_relative_time_t s_inflight_since = 0;

/* ------------------------------------------------------------------ */
/*  Internal helpers                                                    */
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
        ESP_LOGI(TAG, "NVS updated after pop (%d remaining)", s_queue.count);
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

/* Reset msg_id on every undelivered entry and advance the connection epoch. */
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
             * msg_ids are stale and must be cleared. */
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
    if (s_queue.count >= EVENT_OUTBOX_MAX_ENTRIES) {
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

    ESP_LOGI(TAG, "Pushed seq=%" PRIu32 " type=%d bin=%d count=%d",
             e->seq, event_type, bin_id, s_queue.count);

    return ESP_OK;
}

esp_err_t event_outbox_get(int pos, event_outbox_entry_t *out_entry)
{
    if (pos < 0 || pos >= s_queue.count) {
        return ESP_ERR_NOT_FOUND;
    }

    int idx = (s_queue.head + pos) % EVENT_OUTBOX_MAX_ENTRIES;
    *out_entry = s_queue.entries[idx];

    return ESP_OK;
}

uint64_t event_outbox_get_conn_epoch(void)
{
    return s_conn_epoch;
}

esp_err_t event_outbox_set_msg_id(uint32_t seq, int msg_id, uint64_t conn_epoch)
{
    /* If the epoch has advanced, a disconnect fired between the publish
     * call and this write.  The entry's msg_id was already reset to -1 by
     * reset_inflight; writing the now-stale id would make the entry look
     * in-flight and block future delivery. */
    if (s_conn_epoch != conn_epoch) {
        return ESP_ERR_INVALID_STATE;
    }

    for (int i = 0; i < s_queue.count; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        if (s_queue.entries[idx].valid && s_queue.entries[idx].seq == seq) {
            s_queue.entries[idx].msg_id = msg_id;
            return ESP_OK;
        }
    }

    return ESP_ERR_NOT_FOUND;
}

esp_err_t event_outbox_ack(int msg_id)
{
    /* Find the in-flight entry with this msg_id and mark it delivered. */
    bool found = false;
    for (int i = 0; i < s_queue.count; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        if (s_queue.entries[idx].valid &&
            !s_queue.entries[idx].delivered &&
            s_queue.entries[idx].msg_id == msg_id) {
            s_queue.entries[idx].delivered = true;
            s_queue.entries[idx].msg_id = -1;
            found = true;
            ESP_LOGI(TAG, "ACK seq=%" PRIu32 " msg_id=%d", s_queue.entries[idx].seq, msg_id);
            break;
        }
    }

    if (!found) {
        return ESP_ERR_NOT_FOUND;
    }

    /* Pop all consecutive delivered entries from the front. */
    while (s_queue.count > 0 && s_queue.entries[s_queue.head].delivered) {
        ESP_LOGI(TAG, "Popping seq=%" PRIu32 ", remaining=%d",
                 s_queue.entries[s_queue.head].seq, s_queue.count - 1);
        pop_front_locked();
    }

    refresh_dirty_state_locked();

    return ESP_OK;
}

void event_outbox_reset_inflight(void)
{
    reset_inflight_nolock();
}

int event_outbox_count(void)
{
    return s_queue.count;
}

bool event_outbox_is_full(void)
{
    return s_queue.count >= EVENT_OUTBOX_MAX_ENTRIES;
}

void event_outbox_tick(void)
{
    rtc_relative_time_t now = app_rtc_get_relative_timestamp();

    /* Periodic NVS persist for unpersisted entries. */
    if (s_dirty_since != 0 && s_queue.count > 0) {
        int64_t age = app_rtc_calc_duration_ms(s_dirty_since, now);
        if (age >= EVENT_OUTBOX_PERSIST_MS) {
            ESP_LOGI(TAG, "Persisting outbox after %lld ms", age);
            save_to_nvs_locked();
        }
    }

    /* Inflight-timeout recovery: if any entry has been in-flight (published
     * but PUBACK not yet received) for longer than EVENT_OUTBOX_INFLIGHT_TIMEOUT_MS,
     * reset all in-flight msg_ids so drain can republish them on the next call.
     * This recovers from dropped PUBACK events (e.g. supervisor queue overflow). */
    bool any_inflight = false;
    for (int i = 0; i < s_queue.count; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        if (s_queue.entries[idx].valid &&
            !s_queue.entries[idx].delivered &&
            s_queue.entries[idx].msg_id >= 0) {
            any_inflight = true;
            break;
        }
    }

    if (any_inflight) {
        if (s_inflight_since == 0) {
            s_inflight_since = now;
        } else {
            int64_t inflight_age = app_rtc_calc_duration_ms(s_inflight_since, now);
            if (inflight_age >= EVENT_OUTBOX_INFLIGHT_TIMEOUT_MS) {
                ESP_LOGW(TAG, "In-flight entries stuck for %lld ms; resetting for republish",
                         inflight_age);
                reset_inflight_nolock();
                s_inflight_since = 0;
            }
        }
    } else {
        s_inflight_since = 0;
    }
}

void event_outbox_drain(void)
{
    /* Snapshot the connection epoch.  If a disconnect fires between publish
     * and recording the msg_id, the epoch will have advanced and we skip
     * the stale msg_id write. */
    uint64_t conn_epoch = s_conn_epoch;

    /* Load persistent device state once for all entries to avoid an NVS
     * read per entry when draining a batch. */
    device_persistent_state_t dev_state;
    bool dev_state_loaded = (devcfg_get_device_state(&dev_state) == ESP_OK);
    const device_persistent_state_t *dev_state_hint = dev_state_loaded ? &dev_state : NULL;

    /* Publish unpublished entries up to a per-call limit.  Bounding the
     * number of concurrent in-flight entries prevents the supervisor queue
     * from being flooded with PUBACK events (queue size = 16;
     * EVENT_OUTBOX_DRAIN_MAX_PER_CALL << 16). */
    int published = 0;
    for (int i = 0; i < s_queue.count && published < EVENT_OUTBOX_DRAIN_MAX_PER_CALL; i++) {
        int idx = (s_queue.head + i) % EVENT_OUTBOX_MAX_ENTRIES;
        event_outbox_entry_t *e = &s_queue.entries[idx];

        /* Skip invalid, already-delivered, or already in-flight entries. */
        if (!e->valid || e->delivered || e->msg_id >= 0) {
            continue;
        }

        int msg_id = -1;
        esp_err_t err = mqtt_publish_event(e, dev_state_hint, &msg_id);
        if (err != ESP_OK) {
            /* Not connected, or broker send-buffer full; retry on next drain. */
            return;
        }

        /* Record the packet ID only if no disconnect raced since we started. */
        if (s_conn_epoch == conn_epoch) {
            e->msg_id = msg_id;
        }

        published++;
    }
}


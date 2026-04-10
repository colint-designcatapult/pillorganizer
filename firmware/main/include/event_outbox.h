#pragma once

#include "supervisor.h"
#include "rtc.h"
#include <esp_err.h>
#include <stdbool.h>
#include <stdint.h>

/*
 * Event Outbox
 *
 * Stores device events reliably across deep-sleep cycles (RTC memory) and
 * full power cycles (NVS backup).  Events are pushed unconditionally as they
 * occur and are only removed after all in-flight entries up to and including
 * that entry have received a QoS-1 PUBACK confirmation.
 *
 * Multiple events may be published simultaneously.  Each entry carries its own
 * MQTT msg_id once published, and is marked `delivered` when the broker ACKs
 * it.  Delivered entries are removed from the front of the queue in FIFO order
 * (an entry cannot be removed until every older entry is also delivered).
 *
 * A stable per-entry `seq` number is used as a handle when associating an
 * MQTT msg_id with an entry after publishing, making the assignment robust
 * against queue modifications between the publish call and the set_msg_id call.
 *
 * Thread-safety: NOT thread-safe.  All public functions MUST be called
 * exclusively from the supervisor event-loop task.
 */

#define EVENT_OUTBOX_MAX_ENTRIES 100

/* Sentinel value for event_outbox_entry_t.bin_id when the event is not
 * associated with a specific bin (e.g. reload, error events). */
#define EVENT_OUTBOX_BIN_ID_NONE (-1)

typedef struct {
    rtc_utc_timestamp_ms timestamp;  /* UTC ms; guaranteed non-zero on push     */
    device_event_type_t  event_type;
    int                  bin_id;     /* EVENT_OUTBOX_BIN_ID_NONE if not bin-specific */
    int                  flags;      /* optional flags (e.g. error code)        */
    uint32_t             seq;        /* monotonic sequence number (stable handle) */
    int                  msg_id;     /* client-assigned packet ID once published; -1 = unpublished */
    bool                 delivered;  /* true = PUBACK confirmed by broker        */
    bool                 valid;
    bool                 persisted;  /* true once saved to NVS                  */
} event_outbox_entry_t;

/*
 * Initialize the event outbox.
 * Must be called early in app_main (after init_nvs(), before mux_io).
 * On cold boot the NVS backup is loaded; on deep-sleep wake the RTC state
 * is used directly (in-flight msg_ids are cleared since MQTT reconnects).
 */
void event_outbox_init(void);

/*
 * Push a new event.
 * Returns ESP_ERR_NO_MEM if the outbox is full (caller must assert
 * DEVERR_OUTBOX_FULL).
 */
esp_err_t event_outbox_push(rtc_utc_timestamp_ms timestamp,
                             device_event_type_t event_type,
                             int bin_id,
                             int flags);

/*
 * Read the entry at logical position `pos` (0 = oldest) into `out_entry`.
 * Returns ESP_ERR_NOT_FOUND if pos >= count.
 */
esp_err_t event_outbox_get(int pos, event_outbox_entry_t *out_entry);

/*
 * Returns the current connection epoch.  The epoch is incremented every time
 * event_outbox_reset_inflight() is called (i.e., on every MQTT disconnect).
 * Callers should snapshot this value before publishing and pass it to
 * event_outbox_set_msg_id() so that a racing disconnect is detected.
 */
uint64_t event_outbox_get_conn_epoch(void);

/*
 * Record the client-assigned MQTT packet ID on the entry identified by `seq`.
 * Using `seq` rather than a positional index makes this safe to call after
 * the mutex was released between event_outbox_get() and this call.
 *
 * `conn_epoch` must be the value obtained from event_outbox_get_conn_epoch()
 * before the corresponding publish call.  If the stored epoch has advanced
 * (i.e., a disconnect fired between the publish and this call), the write is
 * a no-op and ESP_ERR_INVALID_STATE is returned so the caller knows the
 * msg_id is stale and the entry will be republished on reconnect.
 *
 * Returns ESP_ERR_NOT_FOUND if no entry with that seq exists.
 */
esp_err_t event_outbox_set_msg_id(uint32_t seq, int msg_id, uint64_t conn_epoch);

/*
 * Mark the entry with the given MQTT msg_id as delivered (PUBACK received),
 * then pop all consecutive delivered entries from the front of the queue.
 * Returns ESP_ERR_NOT_FOUND if no entry with that msg_id exists.
 */
esp_err_t event_outbox_ack(int msg_id);

/*
 * Reset the msg_id of every undelivered entry back to -1.
 * Call on MQTT disconnect so all in-flight events are republished on
 * the next connection.
 */
void event_outbox_reset_inflight(void);

/* Number of valid entries currently in the outbox. */
int event_outbox_count(void);

/* True when the outbox has reached EVENT_OUTBOX_MAX_ENTRIES. */
bool event_outbox_is_full(void);

/*
 * Periodic maintenance – call once per supervisor tick (~1 s).
 * After an unpersisted entry has been sitting in the outbox for more than
 * 60 seconds the whole queue is flushed to NVS so it survives a full
 * power cycle.
 */
void event_outbox_tick(void);

/*
 * Publish pending outbox entries over MQTT QoS 1.
 *
 * Publishes at most EVENT_OUTBOX_DRAIN_MAX_PER_CALL entries per call to
 * prevent the supervisor event queue from being flooded with PUBACK events.
 * Stops early at the first publish failure (e.g. not connected or broker
 * send-buffer full) so it is safe to call unconditionally.
 *
 * Calling drain again after a PUBACK is acknowledged will publish the next
 * batch of entries.
 *
 * Must be called from the supervisor event-loop task.
 */
void event_outbox_drain(void);

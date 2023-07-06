/**
 * @file wire_codec.h
 * @brief Encodes/decodes structures used by network protocols (i.e. Bluetooth, Wifi).
 *
 * The pill organizer's network communications, whether over Bluetooth or WiFi, is 
 */

#pragma once

#include "pb.h"
#include "pill.pb.h"
#include "pill_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \defgroup Common Protobuf field encoders
 */
/**@{*/
/** Encode a device ID */
bool encode_device_id(pb_ostream_t *stream, const pb_field_t *field, void* const *arg);
/** Encode a WiFi BSSID */
bool encode_bssid(pb_ostream_t *stream, const pb_field_t *field, void* const *arg);
/** Encode a WiFi SSID */
bool encode_ssid(pb_ostream_t *stream, const pb_field_t *field, void* const *arg);
/** Encode an OOB key */
bool encode_oob_key(pb_ostream_t *stream, const pb_field_t *field, void* const *arg);
/** Encode all queued bin events and remove them from the queue */
bool encode_queued_events(pb_ostream_t *stream, const pb_field_t *field, void * const *arg);
/** Encode all queued bin events but keep them in the queue */
bool encode_queued_events_peek(pb_ostream_t *stream, const pb_field_t *field, void * const *arg);
/**@}*/

/**
 * @brief Builds a barebones SyncRequest (with hash and state) from the current device's state. The device's state is 
 * acquired automatically.
 * 
 * @param req SyncRequest structure to build into
 */
void encode_sync_request(SyncRequest* req, bool peek);



#ifdef __cplusplus
}
#endif
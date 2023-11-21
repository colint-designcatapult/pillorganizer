#include "wire_codec.h"
#include "wifi.h"
#include "pb_encode.h"
#include "pill_state.h"
#include "event.h"
#include "engineering.h"

bool encode_device_id(pb_ostream_t *stream, const pb_field_t *field, void * const *arg) {
    if (!pb_encode_tag_for_field(stream, field))
        return false;

    const wifi_info_t*  wifi_info = wifi_get_info();
    return pb_encode_string(stream, (uint8_t*)wifi_info->sn.bytes.mac, sizeof(wifi_info->sn.bytes.mac));
}

bool encode_bssid(pb_ostream_t *stream, const pb_field_t *field, void * const *arg) {
    if (!pb_encode_tag_for_field(stream, field))
        return false;

    const wifi_info_t*  wifi_info = wifi_get_info();
    return pb_encode_string(stream, (uint8_t*)wifi_info->bssid, sizeof(wifi_info->bssid));
}

bool encode_ssid(pb_ostream_t *stream, const pb_field_t *field, void * const *arg) {
    if (!pb_encode_tag_for_field(stream, field))
        return false;

    const wifi_info_t*  wifi_info = wifi_get_info();
    return pb_encode_string(stream, (uint8_t*)wifi_info->ssid, strlen(wifi_info->ssid));
}

static void build_recorded_event_from_event(BinEvent* src, RecordedEvent* dest) {
    dest->bin       = src->bin;
    dest->timestamp = src->timestamp;
    if(src->event == BIN_EVENT_OPENED) {
        dest->type = RecordedEvent_EventType_OPENED;
    } else if(src->event == BIN_EVENT_CLOSED) {
        dest->type = RecordedEvent_EventType_CLOSED;
    } else if(src->event == BIN_EVENT_MISSED) {
        dest->type = RecordedEvent_EventType_MISSED;
    }
    dest->has_bin   = dest->bin >= 0;
}


bool encode_queued_events(pb_ostream_t *stream, const pb_field_t *field, void * const *arg)
{
    BinEvent be = { 0 };

    while(xQueueReceive(event_bin_queue(), &be, 0)) {
        if(!pb_encode_tag_for_field(stream, field))
            return false;

        RecordedEvent rec = RecordedEvent_init_zero;
        rec.bin             = be.bin;
        rec.has_bin         = be.bin != BIN_NULL;
        rec.timestamp       = be.timestamp;
        rec.type            = be.event;
        build_recorded_event_from_event(&be, &rec);

        if(!pb_encode_submessage(stream, RecordedEvent_fields, &rec))
            return false;
    }
    return true;
}

bool encode_queued_events_peek(pb_ostream_t *stream, const pb_field_t *field, void * const *arg)
{
    BinEvent be = { 0 };
    for(UBaseType_t c = 0; c < uxQueueMessagesWaiting(event_bin_queue()); c++) {
        xQueueReceive(event_bin_queue(), &be, 0);

        if(!pb_encode_tag_for_field(stream, field))
            return false;

        RecordedEvent rec = RecordedEvent_init_zero;
        rec.bin             = be.bin;
        rec.has_bin         = be.bin != BIN_NULL;
        rec.timestamp       = be.timestamp;
        rec.type            = be.event;
        build_recorded_event_from_event(&be, &rec);

        if(!pb_encode_submessage(stream, RecordedEvent_fields, &rec))
            return false;

        // Return item to queue
        xQueueSendToBack(event_bin_queue(), &be, pdMS_TO_TICKS(10));
    }
    return true;
}

void encode_sync_request(SyncRequest* req, bool peek) {
    // todo: move state function into here

    // send in engineering data
    engineering_build_sync(req);

    // requires private fields in pill_state.c
    state_build_sync_request(req);

    const wifi_info_t*  wifi_info = wifi_get_info();
    
    // Copy IPv4
    req->ipv4 = wifi_info->ip4.addr;
    req->has_ipv4 = wifi_info->has_ip4;

    // Only copy in IPv6 if we have it
    if(wifi_info->has_ip6) {
        memcpy(req->ipv6, wifi_info->ip6.addr, 16);
        req->has_ipv6 = true;
    }

    req->events.funcs.encode = peek ? &encode_queued_events_peek : &encode_queued_events;
}
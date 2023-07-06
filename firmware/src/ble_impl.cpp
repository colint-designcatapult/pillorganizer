#include "ble_impl.h"
#include "wire_codec.h"

#include "pb_encode.h"
#include "pb_decode.h"

#include "esp_log.h"

#define TAG "PillBleIMPL"

// Todo: make these headers C++-compat so we don't have to wrap it in extern
extern "C" {
    #include "pill_state.h"
}

int ble_send_pb(ble_gatt_access_ctxt* ctxt, const pb_ostream_t& data, uint8_t* buf) {
    return os_mbuf_append(ctxt->om, buf, data.bytes_written);
}


int BinsStateCharacteristic::read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) {
    if(xSemaphoreTake(event_bin_queue_mutex(), pdMS_TO_TICKS(10))) {
        build_sync();

        uint8_t buffer[512];
        pb_ostream_t ostream = pb_ostream_from_buffer(buffer, sizeof(buffer));
        pb_encode(&ostream, SyncRequest_fields, &req);

        ESP_LOGI(TAG, "Bluetooth Sync started");
        xSemaphoreGive(event_bin_queue_mutex());

        return ble_send_pb(ctxt, ostream, buffer);
    } else {
        ESP_LOGW(TAG, "Failed to acquire queue mutex");
        return 0;
    }
}




int BinsStateCharacteristic::write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) {
        uint8_t buffer[512];
        uint16_t len;
        SyncResponse resp = SyncResponse_init_zero;
        
        int err;
        if((err = ble_receive(ctxt->om, 0, sizeof(buffer), buffer, &len)) != 0)
            return 0;

        pb_istream_t stream = pb_istream_from_buffer((pb_byte_t*)buffer, len);
        if(!pb_decode(&stream, SyncResponse_fields, &resp)) {
            return 0;
        }
    
        state_set_schedule(resp.schedule, resp.schedule_count);
        if(resp.has_bin_state)
            state_set_state(&resp.bin_state);

        // Clear events
        // todo: clear only persisted events
        xQueueReset(event_bin_queue());

        ESP_LOGI(TAG, "Bluetooth Sync complete");

    return 0;
}

void BinsStateCharacteristic::build_sync() {
    req = SyncRequest_init_default;
    encode_sync_request(&req, true);
    built = true;
}


void BinsStateCharacteristic::handle(esp_event_base_t base, int32_t id, void* event_data) {
    // disabled - broken and we don't use notify on this anyway
    /*build_sync();
    if(last_hash != req.state_hash)
        notify();*/
}

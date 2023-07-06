#pragma once
#include "ble.h"
#include "event.h"
#include "ota.h"

using BinBitmaskCharacteristicUUID = BleUUID128<0xB0,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class BinBitmaskCharacteristic : public BaseGattCharacteristic<BinBitmaskCharacteristicUUID>,
                                 public AutoEventHandler<BIN_EVENT_BASE, BIN_EVENT_BITMASK_CHANGED> {
protected:
    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        return ble_send(ctxt, bitmask);
    }

    void handle(esp_event_base_t base, int32_t id, void* event_data) override {
        bitmask = ((BinEventBitmaskChanged*)event_data)->bitmask;
        this->notify();
    }

    bool readable() override {
        return true;
    }

    bool notifyable() override {
        return true;
    }

private:
    uint16_t bitmask;
};

using BinSamplesCharacteristicUUID = BleUUID128<0xB1,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class BinSamplesCharacteristic : public BaseGattCharacteristic<BinSamplesCharacteristicUUID>,
                                 public AutoEventHandler<BIN_EVENT_BASE, BIN_EVENT_SAMPLES> {
protected:
    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        return ble_send(ctxt, samples);
    }

    void handle(esp_event_base_t base, int32_t id, void* event_data) override {
        BinEventSamples* ev = (BinEventSamples*)event_data;
        for(int i = 0; i < 16; i++) {
            samples[i] = ev->samples[i];
        }
        this->notify();
    }

    bool readable() override {
        return true;
    }

    bool notifyable() override {
        return true;
    }

private:
    uint16_t samples[16];
};

using BinsStateCharacteristicUUID = BleUUID128<0xC1,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class BinsStateCharacteristic : public BaseGattCharacteristic<BinsStateCharacteristicUUID>,
                                public AutoEventHandler<BIN_EVENT_BASE, BIN_EVENT> {
public:
    BinsStateCharacteristic() : req(SyncRequest_init_default), last_hash(0) {}
protected:
    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override;
    int write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override;
    void handle(esp_event_base_t base, int32_t id, void* event_data) override;

    void build_sync();

    bool readable() override {
        return true;
    }
    
    bool writable() override {
        return true;
    }

private:
    bool built = false;
    SyncRequest req;
    int64_t last_hash = 0;
};

using BinEventCharacteristicUUID = BleUUID128<0xD1,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class BinEventCharacteristic : public BaseGattCharacteristic<BinEventCharacteristicUUID> {
protected:
    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        //return ble_send(ctxt, samples);
        return 0;
    }

    bool readable() override {
        return true;
    }

    bool notifyable() override {
        return true;
    }

private:
};

using BinEventAckCharacteristicUUID = BleUUID128<0xD2,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class BinEventAckCharacteristic : public BaseGattCharacteristic<BinEventAckCharacteristicUUID> {
protected:
    int write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        //return ble_send(ctxt, samples);
        return 0;
    }


    bool writable() override {
        return true;
    }


private:
};



using PillOrganizerServiceUUID = BleUUID128<0xA5,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                                0x5B,0x76,0xD8,0xDE,0x20>;
using PillOrganizerService = BaseGattService<PillOrganizerServiceUUID, BinBitmaskCharacteristic, BinSamplesCharacteristic, BinsStateCharacteristic, BinEventCharacteristic, BinEventAckCharacteristic>;


using BatteryLevelCharacteristicUUID = BleUUID16<0x2A19>;
class BatteryLevelCharacteristic : public BaseGattCharacteristic<BatteryLevelCharacteristicUUID>,
                                   public AutoEventHandler<POWER_EVENT_BASE, POWER_EVENT_BATTERY_LEVEL_CHANGE>  {
protected:
    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        return ble_send(ctxt, (uint8_t)67);
    }

    void handle(esp_event_base_t base, int32_t id, void* event_data) override {
        if(base == POWER_EVENT_BASE) {
            if(id == POWER_EVENT_BATTERY_LEVEL_CHANGE) {
                level = ((PowerBatteryLevelChangeEvent*)event_data)->battery_level; 
                notify();
            }
        }
    }

    bool readable() override {
        return true;
    }

    bool notifyable() override {
        return true;
    }
private:
    uint8_t level = 0;
};

using BatteryLevelStatusCharacteristicUUID = BleUUID16<0x2BED>;
class BatteryLevelStatusCharacteristic : public BaseGattCharacteristic<BatteryLevelStatusCharacteristicUUID>,
                                         public AutoEventHandler<POWER_EVENT_BASE> {
protected:
    BLE_STRUCT BatteryStatus {
        bool identifier_present:1;
        bool battery_level_present:1;
        bool additional_status_present:1;
        int rfu_1:5;
        bool battery_present:1;
        int wired_external_power_source:2;
        int wireless_external_power_source:2;
        int battery_charge_state:2;
        int battery_charge_level:2;
        int charging_type:3;
        int charging_fault_reason:2;
        int rfu_2:1;
        uint8_t battery_level;
    };
    static_assert(sizeof(BatteryLevelStatusCharacteristic::BatteryStatus) == 4);

    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        return ble_send(ctxt, status);
    }

    void handle(esp_event_base_t base, int32_t id, void* event_data) override {
        if(base == POWER_EVENT_BASE) {
            if(id == POWER_EVENT_STATUS_CHANGE) {
                PowerStatusChangeEvent* ev = (PowerStatusChangeEvent*)event_data;
                status.battery_present              = ev->battery_present;
                status.wired_external_power_source  = ev->plugged_in ? 1 : 0;
                status.charging_type                = ev->charging ? 1 : 0;
                notify();
            } else if(id == POWER_EVENT_BATTERY_LEVEL_CHANGE) {
                status.battery_level            = ((PowerBatteryLevelChangeEvent*)event_data)->battery_level; 
                status.battery_level_present    = 1;
                notify();
            }
        }
    }

    bool readable() override {
        return true;
    }

    bool notifyable() override {
        return true;
    }
private:
    BatteryLevelStatusCharacteristic::BatteryStatus status;
};



using BatteryServiceUUID = BleUUID16<0x180F>;
using BatteryService = BaseGattService<BatteryServiceUUID, BatteryLevelCharacteristic, BatteryLevelStatusCharacteristic>;



using FWUpdateCharacteristicUUID = BleUUID128<0xB0,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class FWUpdateCharacteristic : public BaseGattCharacteristic<FWUpdateCharacteristicUUID> {
protected:

    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        return ble_send(ctxt, last_resp);
    }

    int write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt *ctxt) override {
        uint8_t buffer[512];
        uint16_t len;
        
        int err;
        if((err = ble_receive(ctxt->om, 0, sizeof(buffer), buffer, &len)) != 0)
            return 0;

        size_t bw;
        return ota_update(OTA_METHOD_BLE, buffer, len, &last_resp, sizeof(last_resp), &bw);
    }


    bool readable() override {
        return true;
    }
    bool writable() override {
        return true;
    }

private:
    ota_update_response last_resp;
};

using FWVersionCharacteristicUUID = BleUUID128<0xB8,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class FWVersionCharacteristic : public BaseGattCharacteristic<FWVersionCharacteristicUUID> {
protected:

    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override {
        int32_t out;
        size_t bout;
        ota_get_current_version(nullptr, 0, &out, sizeof(out), &bout);
        return ble_send(ctxt, bout);
    }


    bool readable() override {
        return true;
    }

private:
    ota_update_response last_resp;
};




using OTAUpdateServiceUUID = BleUUID128<0xA9,0x26,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                                0x5B,0x76,0xD8,0xDE,0x20>;
using OTAUpdateService = BaseGattService<OTAUpdateServiceUUID, FWUpdateCharacteristic, FWVersionCharacteristic>;


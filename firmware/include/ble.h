#pragma once
#include "nimble/ble.h"

// Whether the BLE backend is running without WiFi
//       Set to TRUE when ESP32 Wifi Provisioning is not in use
#define BLE_STANDALONE  true


#define BLE_STRUCT struct __attribute__((__packed__))

#ifdef __cplusplus
extern "C" {
#endif

void ble_init();
bool ble_has_sync_preemption();

#ifdef __cplusplus
}
#endif


// For implementation

#ifdef __cplusplus

#include "host/ble_gatt.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
constexpr ble_gatt_svc_def empty_svc = {.type = 0};
constexpr ble_gatt_chr_def empty_chr = {.uuid = nullptr};
constexpr ble_gatt_dsc_def empty_dsc = {.uuid = nullptr};
#pragma GCC diagnostic pop

template<typename T>
int ble_send(ble_gatt_access_ctxt* ctxt, const T& data) {
    return os_mbuf_append(ctxt->om, &data, sizeof(T));
}

int ble_receive(struct os_mbuf *om, uint16_t min_len, uint16_t max_len,
               void *dst, uint16_t *len);

template<typename T, uint8_t E, typename VT, VT VAL>
struct BleUUID {
    static constexpr T val = {
        .u = {.type = E},
        .value = VAL
    };
};


template<uint8_t... VAL>
struct BleUUID128 {
    static constexpr ble_uuid128_t val = {
        .u = {.type = BLE_UUID_TYPE_128},
        .value = {VAL...}
    };
};
template<uint32_t VAL>
using BleUUID32 = BleUUID<ble_uuid32_t, BLE_UUID_TYPE_32, uint32_t, VAL>;
template<uint16_t VAL>
using BleUUID16 = BleUUID<ble_uuid16_t, BLE_UUID_TYPE_16, uint16_t, VAL>;


class _AbstractGattAccessible {
protected:
    virtual int access(uint16_t conn_handle, uint16_t attr_handle,
                            struct ble_gatt_access_ctxt *ctxt);
    virtual int read(uint16_t conn_handle, uint16_t attr_handle,
                            struct ble_gatt_access_ctxt *ctxt) {
        return 1;
    }
    virtual int write(uint16_t conn_handle, uint16_t attr_handle,
                            struct ble_gatt_access_ctxt *ctxt) {
        return 1;
    }

    static int access_cb(uint16_t conn_handle, uint16_t attr_handle,
                               struct ble_gatt_access_ctxt *ctxt, void *arg) {
        return ((_AbstractGattAccessible*)arg)->access(conn_handle, attr_handle, ctxt);
    }

    virtual bool readable() = 0;
    virtual bool writable() = 0;
    virtual bool notifyable() = 0;
    virtual bool indicatable() = 0;
};



template<typename UUID>
class BaseGattDescriptor : public _AbstractGattAccessible {
public:
    static constexpr ble_gatt_dsc_def definition = {
        .uuid = &UUID::val.u,
        .att_flags = 0,
        .min_key_size = 0,
        .access_cb = 0,
        .arg = 0
    };

    void init(ble_gatt_dsc_def* def) {
        def->arg = this;
        def->access_cb = access_cb;
        def->att_flags = build_flags();
    }

    uint8_t build_flags() {
        uint8_t flags = 0;
        if(this->readable())
            flags |= BLE_ATT_F_READ;
        if(this->writable())
            flags |= BLE_ATT_F_WRITE;
        return flags;
    }
protected:
    virtual bool readable() override {
        return false;
    }

    virtual bool writable() override {
        return false;
    }

    virtual bool notifyable() override {
        return false;
    }

    virtual bool indicatable() override {
        return false;
    }
};

template<typename UUID, class... DESCRS>
class BaseGattCharacteristic : public _AbstractGattAccessible {
public:
    static constexpr ble_gatt_dsc_def dscrs_cexpr[sizeof...(DESCRS) + 1] = {
            (DESCRS::definition)...,
            empty_dsc
    };
    static constexpr ble_gatt_chr_def definition = {
        .uuid = &UUID::val.u,
        .access_cb = nullptr,
        .arg = nullptr,
        .descriptors = nullptr,
        .flags = 0,
        .min_key_size = 0,
        .val_handle = nullptr
    };

    BaseGattCharacteristic() : descrs(dscrs_cexpr) {}

    void init(ble_gatt_chr_def* def) {
        def->arg = static_cast<_AbstractGattAccessible*>(this);
        def->access_cb = access_cb;
        def->val_handle = &_handle;
        def->flags = build_flags();

        // Initialize all child descriptors
        size_t index = 0;
        (init_dsc<DESCRS>(&descrs[index++]), ...);

        // Set characteristics pointer to actual value
        def->descriptors = descrs;
    }

    ble_gatt_chr_flags build_flags() {
        ble_gatt_chr_flags flags = 0;
        if(this->readable())
            flags |= BLE_GATT_CHR_F_READ;
        if(this->writable())
            flags |= BLE_GATT_CHR_F_WRITE;
        if(this->notifyable())
            flags |= BLE_GATT_CHR_F_NOTIFY;
        if(this->indicatable())
            flags |= BLE_GATT_CHR_F_INDICATE;
        return flags;
    }

    template<class Desc>
    void init_dsc(ble_gatt_dsc_def* def) {
        Desc* inst = new Desc();
        inst->init(def);
    }

    void notify() {
        ble_gatts_chr_updated(_handle);
    }

protected:
    virtual bool readable() override {
        return false;
    }

    virtual bool writable() override {
        return false;
    }

    virtual bool notifyable() override {
        return false;
    }

    virtual bool indicatable() override {
        return false;
    }
protected:
    uint16_t _handle; 
private:
    ble_gatt_dsc_def descrs[sizeof...(DESCRS) + 1];
};


template<typename UUID, class... CHARS>
struct BaseGattService {
    static constexpr ble_gatt_chr_def chars_cexpr[sizeof...(CHARS) + 1] = {
            (CHARS::definition)...,
            empty_chr
    };
    static constexpr ble_gatt_svc_def definition = {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &UUID::val.u,
        .includes = nullptr,
        .characteristics = nullptr
    };
    static constexpr ble_uuid128_t uuid = UUID::val;

    ble_gatt_chr_def chars[sizeof...(CHARS) + 1];

    BaseGattService() : chars(chars_cexpr) {}

    void init(ble_gatt_svc_def* def) {
        // Initialize all child characteristics
        size_t index = 0;
        (init_char<CHARS>(&chars[index++]), ...);

        // Set characteristics pointer to actual value
        def->characteristics = chars;

    }

    template<class Char>
    void init_char(ble_gatt_chr_def* def) {
        Char* inst = new Char();
        inst->init(def);
    }
};


#endif
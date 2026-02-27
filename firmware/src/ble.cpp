#include "eternal.hpp"

#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"

#include "esp_log.h"
#include "ble.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "esp_err.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"
#include "services/ans/ble_svc_ans.h"
#include "host/ble_hs.h"
#include "host/util/util.h"
#include "ble_impl.h"
#include "util.h"


#define TAG              "PillBLE"


#ifdef NDEBUG
#define BLE_ERROR_CHECK(x) do {                                         \
        int err_ble_ = (x);                                        \
        (void) sizeof(err_ble_);                                         \
    } while(0)
#elif defined(CONFIG_COMPILER_OPTIMIZATION_ASSERTIONS_SILENT)
#define BLE_ERROR_CHECK(x) do {                                         \
        int err_ble_ = (x);                                        \
        if (unlikely(err_ble_ != 0)) {                              \
            abort();                                                    \
        }                                                               \
    } while(0)
#else
#define BLE_ERROR_CHECK(x) do {                                         \
        int err_ble_ = (x);                                        \
        if (unlikely(err_ble_ != 0)) {                              \
            _esp_error_check_failed(err_ble_, __FILE__, __LINE__,        \
                                    __ASSERT_FUNC, #x);                 \
        }                                                               \
    } while(0)
#endif

#define PRAddr     "%02x:%02x:%02x:%02x:%02x:%02x"
#define PRAddrP(x) x[5], x[4], x[3], x[2], x[1], x[0] 

static bool sync_preempt = false;

extern "C" bool ble_has_sync_preemption() {
    return sync_preempt;
}

extern "C" void bleprph_host_task(void *param)
{
    ESP_LOGI(TAG, "BLE Host Task Started");
    /* This function will return only when nimble_port_stop() is executed */
    nimble_port_run();

    nimble_port_freertos_deinit();
}

int ble_receive(struct os_mbuf *om, uint16_t min_len, uint16_t max_len,
               void *dst, uint16_t *len) {
    uint16_t om_len;
    int rc;

    om_len = OS_MBUF_PKTLEN(om);
    if (om_len < min_len || om_len > max_len) {
        return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
    }

    rc = ble_hs_mbuf_to_flat(om, dst, max_len, len);
    if (rc != 0) {
        return BLE_ATT_ERR_UNLIKELY;
    }

    return 0;
}

void ble_services_changed(bool start_gatt = false) {
    // Attempt to clear GATT client cache
    ble_svc_gatt_changed(0x0001, 0xffff);

    if(start_gatt) {
        ESP_LOGI(TAG, "GATT start in services changed returned with %d", ble_gatts_start());
    }
}

class PillBleGap {
    friend class BlePeripheral;
private:
    void init() {
        ble_svc_gap_init();
        // TODO: add device serial number to BLE device name
        ble_svc_gap_device_name_set("Cabinet");
    }

    void advertise();
    static int gap_event_handler(struct ble_gap_event *event, void *arg);

    int event_connect(ble_gap_event *event) {
        ESP_LOGI(TAG, "connection %s; status=%d ",
                    event->connect.status == 0 ? "established" : "failed",
                    event->connect.status);
        if (event->connect.status != 0) {
            advertise();
        } else {
            ESP_LOGI(TAG, "Bluetooth sync pre-emption active %p", xTaskGetCurrentTaskHandle());
            sync_preempt = true;
        }
        return 0;
    }

    int event_disconnect(ble_gap_event *event) {
        ESP_LOGI(TAG, "disconnect; reason=0x%x ", event->disconnect.reason);
        advertise();
        ESP_LOGI(TAG, "Bluetooth sync pre-emption lifted");
        sync_preempt = false;
        return 0;
    }

    int event_connection_update(ble_gap_event *event) {
        return 0;
    }

    int event_advertise_complete(ble_gap_event *event) {
        return 0;
    }

    int event_encryption_change(ble_gap_event* event) {
        return 0;
    }

    int event_notify_tx(ble_gap_event* event) {
        return 0;
    }

    int event_subscribe(ble_gap_event* event) {
        ESP_LOGI(TAG, "subscribe event; conn_handle=%d attr_handle=%d "
                          "reason=%d prevn=%d curn=%d previ=%d curi=%d\n",
                    event->subscribe.conn_handle,
                    event->subscribe.attr_handle,
                    event->subscribe.reason,
                    event->subscribe.prev_notify,
                    event->subscribe.cur_notify,
                    event->subscribe.prev_indicate,
                    event->subscribe.cur_indicate);
        return 0;
    }

    int event_mtu(ble_gap_event* event) {
        ESP_LOGI(TAG, "mtu update; channel=%d; size=%d\n", event->mtu.channel_id, event->mtu.value);
        return 0;
    }

    int event_repeat_pairing(ble_gap_event* event) {
        return 0;
    }

    int event_passkey_action(ble_gap_event* event) {
        return 0;
    }
};



int _AbstractGattAccessible::access(uint16_t conn_handle, uint16_t attr_handle,
                            struct ble_gatt_access_ctxt *ctxt)  {
    uint8_t op = ctxt->op;
    if(this->readable() && (op == BLE_GATT_ACCESS_OP_READ_CHR || op == BLE_GATT_ACCESS_OP_READ_DSC)) {
        return this->read(conn_handle, attr_handle, ctxt);
    } else if(this->writable() && (op == BLE_GATT_ACCESS_OP_WRITE_CHR || op == BLE_GATT_ACCESS_OP_WRITE_DSC)) {
        return this->write(conn_handle, attr_handle, ctxt); 
    }
    return 0;
}



template<class... SVC>
class BaseBleGatt {
    friend class BlePeripheral;

public:
    void build_advertise_fields(ble_hs_adv_fields* fields) {
        // TODO: Add UUIDs for provisioning services once implemented
        // Currently no services defined
    }
private:
    static constexpr std::initializer_list<ble_gatt_svc_def> service_definitions_cexpr = {
        (SVC::definition)...,
        empty_svc,
    };

    ble_gatt_svc_def defs[service_definitions_cexpr.size()];

    void init() {
        // Create mutable definition, copied from static version
        memcpy(defs, service_definitions_cexpr.begin(), sizeof(defs));

        // Ordered and typed initialization of every service
        size_t index = 0;
        (init_service<SVC>(defs, index++), ...);

        ble_svc_gatt_init();
        
        BLE_ERROR_CHECK(ble_gatts_count_cfg(defs));
        BLE_ERROR_CHECK(ble_gatts_add_svcs(defs));

        index = 0;
    }

    template<class Svc>
    void init_service(ble_gatt_svc_def* defs, size_t index) {
        ble_gatt_svc_def* def = &defs[index];

        char uuid_buf[BLE_UUID_STR_LEN];
        ESP_LOGI(TAG, "Registered service %s", ble_uuid_to_str(def->uuid, uuid_buf));

        Svc* svc = new Svc();
        svc->init(def);
        service_inst[index] = svc;
    }

    template<class Svc>
    void free_service(size_t index) {
        Svc* svc = (Svc*)service_inst[index];
        delete svc;
    }

    std::array<void*, sizeof...(SVC)> service_inst;

};



/*
 *
 *    BLE Services
 *
 */

// Provisioning Service - handles WiFi credentials, serial number, and certificate exchange
using PillBleGatt = BaseBleGatt<
    ProvisioningService
>;

/*
 *
 *    ---------------
 *
 */


class BlePeripheral {
public:
    static BlePeripheral& get() {
        return _instance;
    }

    void init() {
        ESP_LOGI(TAG, "Bluetooth peripheral starting in standalone mode");
        nimble_port_init();
        set_host_callbacks();
        gap().init();
        gatt().init();
        nimble_port_freertos_init(bleprph_host_task);
    }

    PillBleGap& gap() {
        return _gap;
    }

    PillBleGatt& gatt() {
        return _gatt;
    }

private:
    void set_host_callbacks() {
        ble_hs_cfg.reset_cb = bleprph_on_reset;
        ble_hs_cfg.sync_cb = bleprph_on_sync;
        //ble_hs_cfg.gatts_register_cb = gatt_svr_register_cb;
        ble_hs_cfg.store_status_cb = ble_store_util_status_rr;
    }

    void init_host() {
        gap().advertise();
    }

    static void bleprph_on_reset(int reason) {
        ESP_LOGE(TAG, "Resetting state; reason=%d", reason);
    }

    
    static void bleprph_on_sync(void) {
        ESP_LOGI(TAG, "Bluetooth peripheral sync");
        _instance.init_host();
    }


private:
    static BlePeripheral _instance;

    PillBleGap _gap;
    PillBleGatt _gatt;
};

BlePeripheral BlePeripheral::_instance;

    void PillBleGap::advertise() {
        BLE_ERROR_CHECK(ble_hs_util_ensure_addr(0));
        uint8_t own_addr_type;
        BLE_ERROR_CHECK(ble_hs_id_infer_auto(0, &own_addr_type));

        uint8_t addr_val[6] = {0};
        ble_hs_id_copy_addr(own_addr_type, addr_val, NULL);
        ESP_LOGI(TAG, "Bluetooth address: " PRAddr, PRAddrP(addr_val));

        ble_gap_adv_params gap_params{};
        gap_params.conn_mode = BLE_GAP_CONN_MODE_UND;
        gap_params.disc_mode = BLE_GAP_DISC_MODE_GEN;

        ble_hs_adv_fields hs_fields{};
        hs_fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
        hs_fields.tx_pwr_lvl_is_present = true;
        hs_fields.tx_pwr_lvl = BLE_HS_ADV_TX_PWR_LVL_AUTO;

        const char* name = ble_svc_gap_device_name();
        hs_fields.name = (uint8_t *)name;
        hs_fields.name_len = strlen(name);
        hs_fields.name_is_complete = true;

        BlePeripheral::get().gatt().build_advertise_fields(&hs_fields);

        BLE_ERROR_CHECK(ble_gap_adv_set_fields(&hs_fields));
        BLE_ERROR_CHECK(ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER,
                           &gap_params, gap_event_handler, this));
    }

    int PillBleGap::gap_event_handler(struct ble_gap_event *event, void *arg) {
        PillBleGap* inst = (PillBleGap*)arg;

        switch(event->type) {
            case BLE_GAP_EVENT_CONNECT: return inst->event_connect(event);
            case BLE_GAP_EVENT_DISCONNECT: return inst->event_disconnect(event);
            case BLE_GAP_EVENT_CONN_UPDATE: return inst->event_connection_update(event);
            case BLE_GAP_EVENT_ADV_COMPLETE: return inst->event_advertise_complete(event);
            case BLE_GAP_EVENT_ENC_CHANGE: return inst->event_encryption_change(event);
            case BLE_GAP_EVENT_NOTIFY_TX: return inst->event_notify_tx(event);
            case BLE_GAP_EVENT_SUBSCRIBE: return inst->event_subscribe(event);
            case BLE_GAP_EVENT_MTU: return inst->event_mtu(event);
            case BLE_GAP_EVENT_REPEAT_PAIRING: return inst->event_repeat_pairing(event);
            case BLE_GAP_EVENT_PASSKEY_ACTION: return inst->event_passkey_action(event);
            default: return 0;
        }
    }

static TaskHandle_t task;


extern "C" void task_function(void* p1) {
    vTaskDelay(pdMS_TO_TICKS(1000));
    BlePeripheral::get().init();
    vTaskDelete(task);
}

extern "C" void ble_init() {
    // Initialize BLE in standalone mode
    xTaskCreate(task_function, "BLE", 4096, nullptr, tskIDLE_PRIORITY, &task);
}

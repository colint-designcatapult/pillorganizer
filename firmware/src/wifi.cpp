extern "C" {
#include "wifi.h"
#include "network.h"
#include "pill_gpio.h"
#include "util.h"
#include "ota.h"
#include "rtc_sntp.h"

#include <esp_wifi.h>
#include <wifi_provisioner.h>
#include <esp_event.h>
#include <esp_err.h>
#include <esp_log.h>
#include <esp_mac.h>
#include <esp_nimble_hci.h>
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "services/gatt/ble_svc_gatt.h"
}

#include "event.h"

#define TAG "Newifi"

class WifiEventListener {
public:
    virtual void wifi_event_start() {}
    virtual void wifi_event_connected(wifi_event_sta_connected_t*) {}
    virtual void wifi_event_disconnected(wifi_event_sta_disconnected_t*) {}
    virtual void wifi_event_got_ip(ip_event_got_ip_t*) {}
    virtual void wifi_event_got_ip6(ip_event_got_ip6_t*) {}
    virtual void wifi_event_lost_ip() {}
};

class WifiHandler : public WifiEventListener {
public:
    virtual ~WifiHandler() = default;
    virtual void init() = 0;
};

class WifiStateSupervisor : public WifiEventListener {
    friend class ProvisioningWifiHandler;
    friend class StandardWifiHandler;
public:

    bool has_handler() const {
        return _wifi_handler != nullptr; 
    }

    WifiHandler* handler() const {
        return _wifi_handler;
    }

    void init();
    
    void init_early() {
        _event_group = xEventGroupCreateStatic(&_event_group_storage);

        // Initially mark event group as disconnected
        this->on_wifi_disconnected();
    }

    bool wait_for_event(EventBits_t event, TickType_t ticks_to_wait) {
        EventBits_t out = xEventGroupWaitBits(this->_event_group, event, pdFALSE, pdFALSE, ticks_to_wait);
        return (out & event) != 0; 
    }

    bool is_connected() {
         EventBits_t bits = xEventGroupGetBits(this->_event_group);
         return (bits & WIFI_BIT_CONNECTED) != 0;
    }

    wifi_info_t* wifi_info() {
        return &_wifi_info;
    }

    static void event_dispatcher(void* arg, esp_event_base_t event_base,
                          int32_t event_id, void* event_data) {
        if(event_base == WIFI_EVENT) {
            if(event_id == WIFI_EVENT_STA_START) {
                _instance.wifi_event_start();
            } else if(event_id == WIFI_EVENT_STA_CONNECTED) {
                _instance.wifi_event_connected((wifi_event_sta_connected_t*)event_data);
            } else if(event_id == WIFI_EVENT_STA_DISCONNECTED) {
                _instance.wifi_event_disconnected((wifi_event_sta_disconnected_t*)event_data);
            }
        } else if(event_base == IP_EVENT) {
            if(event_id == IP_EVENT_STA_GOT_IP) {
                _instance.wifi_event_got_ip((ip_event_got_ip_t*)event_data);
            } else if(event_id == IP_EVENT_GOT_IP6) {
                _instance.wifi_event_got_ip6((ip_event_got_ip6_t*)event_data);
            } else if(event_id == IP_EVENT_STA_LOST_IP) {
                _instance.wifi_event_lost_ip();
            }
        }
    }

    EventGroupHandle_t event_group() {
        return _event_group;
    }

    static WifiStateSupervisor& get() {
        return _instance;
    }

    /* Event listener proxy */
    void wifi_event_start() override {
        handler()->wifi_event_start();
    }
    void wifi_event_connected(wifi_event_sta_connected_t* e) override {
        handler()->wifi_event_connected(e);

        memcpy(_wifi_info.bssid, e->bssid, 6);
        strncpy(_wifi_info.ssid, (const char*)e->ssid, e->ssid_len);
    }
    void wifi_event_disconnected(wifi_event_sta_disconnected_t* e) override {
        handler()->wifi_event_disconnected(e);
        on_wifi_disconnected();
    }
    void wifi_event_got_ip(ip_event_got_ip_t* e) override {
        handler()->wifi_event_got_ip(e);

        _wifi_info.ip4 = e->ip_info.ip;
        _wifi_info.has_ip4 = true;

        on_wifi_connected();
    }
    void wifi_event_got_ip6(ip_event_got_ip6_t* e) override {
        handler()->wifi_event_got_ip6(e);

        _wifi_info.ip6 = e->ip6_info.ip;
        _wifi_info.has_ip6 = true;

        on_wifi_connected();
    }
    void wifi_event_lost_ip() override {
        handler()->wifi_event_lost_ip();
        on_wifi_disconnected();
    }

private:
    void start_provisioning();
    void switch_to_standard(bool just_provisioned);

protected:
    /* Provisioning wifi handler only */

    // Called to signal end of provisioning (success or failure)
    void on_provision_result(esp_err_t error) {
        if(error == ESP_OK) {
            // Provisioning succeeded, transition to standard wifi handler
            ESP_LOGI(TAG, "Provisioning succeeded");
            this->switch_to_standard(true);
        } else if(error == ESP_ERR_INVALID_STATE) {
            ESP_LOGI(TAG, "This device is already provisioned");
            this->switch_to_standard(false);
        } else {
            // Provisioning failed
            // Rebuild provisioner and try again
            ESP_LOGW(TAG, "Provisioning reported as failed");
            //this->start_provisioning();
            // currently, only restarting is supported
            esp_restart();
        }
    }

    void on_wifi_connected() {
        ESP_LOGI(TAG, "Connected to WiFi");
        xEventGroupSetBits(_event_group, WIFI_BIT_CONNECTED);
        xEventGroupClearBits(_event_group, WIFI_BIT_DISCONNECTED);

        
    }

    void on_wifi_disconnected() {
        ESP_LOGI(TAG, "Disconnected from WiFi");
        _wifi_info.has_ip4 = false;
        _wifi_info.has_ip6 = false;
        xEventGroupSetBits(_event_group, WIFI_BIT_DISCONNECTED);
        xEventGroupClearBits(_event_group, WIFI_BIT_CONNECTED);
    }

private:
    static WifiStateSupervisor _instance;

    wifi_info_t _wifi_info;

    WifiHandler* _wifi_handler = nullptr;
    EventGroupHandle_t _event_group;
    StaticEventGroup_t _event_group_storage;
};



class ProvisioningWifiHandler : public WifiHandler {
private:
    bool _prov_success = false;
    bool _prov_already = false;
    esp_event_handler_instance_t _event_listener;
    wifi_config_t _orig_config;
public:

    ~ProvisioningWifiHandler() {
        // Unregister event listener
        ESP_ERROR_CHECK(esp_event_handler_instance_unregister(WIFI_PROV_EVENT, ESP_EVENT_ANY_ID, _event_listener));
    }

    void event_handler(wifi_prov_cb_event_t event, void *event_data) {
        ESP_LOGI(TAG, "Handling provisioning event %d", event);

        if(event == WIFI_PROV_START) {
            event_post(SYSTEM_EVENT_BASE, SYSTEM_EVENT_PROVISION_START, nullptr, 0, pdMS_TO_TICKS(100));

            if(_prov_already) {
                ESP_LOGI(TAG, "Already provisioned, provision manager stopping");
                wifi_prov_mgr_stop_provisioning();
            } else {
                // start flashing LEDs
                led_set_effect(LED_EFFECT_FLASH_GREEN_AND_RED, INT_MAX);
            }
        } else if(event == WIFI_PROV_CRED_SUCCESS) {
            // Mark provisioning as success
            _prov_success = true;
        } else if(event == WIFI_PROV_CRED_FAIL) {
            // Mark provisioning as failure
            _prov_success = false;
            ESP_ERROR_CHECK(wifi_prov_mgr_reset_sm_state_on_failure());

            // Stop after credential fail
            // Todo: never notifies BLE client
            wifi_prov_mgr_stop_provisioning();
        } else if(event == WIFI_PROV_END) {
            // stop flashing LEDs
            led_set_effect(LED_EFFECT_NORMAL, 0);
            wifi_prov_mgr_deinit();
        } else if(event == WIFI_PROV_DEINIT) {
            ESP_LOGI(TAG, "Provision manager deinit");
            // If already provisioned, return with special error code first indicating device is already provisioned
            if(_prov_already) {
                // Restore original WiFi config
                ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &_orig_config));

                WifiStateSupervisor::get().on_provision_result(ESP_ERR_INVALID_STATE);
            } else {
                WifiStateSupervisor::get().on_provision_result(_prov_success ? ESP_OK : ESP_FAIL);
            }
        } else {
            ESP_LOGI(TAG, "Eating provision event %d", event);
        }
    }
 
    void init() override {
        ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_PROV_EVENT, ESP_EVENT_ANY_ID, event_dispatcher, this, &_event_listener));

        // Configure wifi provisioning manager
        wifi_prov_mgr_config_t config = {
            .scheme = wifi_prov_scheme_ble,
            .scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM
        };

        ESP_ERROR_CHECK(wifi_prov_mgr_init(config));

        bool provisioned = false;
        ESP_ERROR_CHECK(wifi_prov_mgr_is_provisioned(&provisioned));
        ESP_LOGI(TAG, "Provision status= %d", provisioned);
        _prov_already = provisioned;

        if(_prov_already) {
            ESP_ERROR_CHECK(esp_wifi_get_config(WIFI_IF_STA, &_orig_config));
            ESP_LOGI(TAG, "Already provisioned to %s", (const char*)_orig_config.sta.ssid);
        }

        // Start provisioning regardless so we can always piggyback off of ESP-IDF BLE code
        this->start_provisioning();
    }


private:
    void get_device_service_name(char *service_name, size_t max) {
        uint8_t eth_mac[6];
        const char *ssid_prefix = "PROV_";
        esp_wifi_get_mac(WIFI_IF_STA, eth_mac);
        snprintf(service_name, max, "%s%02X%02X%02X",
                ssid_prefix, eth_mac[3], eth_mac[4], eth_mac[5]);
    }

    static void event_dispatcher(void* arg, esp_event_base_t event_base,
                          int32_t event_id, void* event_data) {
        // Proxy to class instance
        ProvisioningWifiHandler* inst = (ProvisioningWifiHandler*)arg;
        assert(inst != nullptr);
        
        if(event_base == WIFI_PROV_EVENT) {
            inst->event_handler((wifi_prov_cb_event_t)event_id, event_data);
        } else {
            ESP_LOGW(TAG, "Unexpected event in provision dispatcher");
        }
    }

    static esp_err_t get_serial_no_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen,
                                          uint8_t **outbuf, ssize_t *outlen, void *priv_data) {
        *outlen = 6;
        *outbuf = new uint8_t[6];
        return esp_efuse_mac_get_default(*outbuf);
    }

    static esp_err_t set_provision_key_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen,
                                          uint8_t **outbuf, ssize_t *outlen, void *priv_data) {
        *outlen = 4;
        *outbuf = new uint8_t[4];
        return network_set_oob_key(inbuf, inlen);
    }


    static esp_err_t fw_version_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen,
                                          uint8_t **outbuf, ssize_t *outlen, void *priv_data) {
        *outbuf = new uint8_t[4];
        ota_get_current_version((void*)inbuf, inlen, *outbuf, 4, (size_t*)outlen);
    }


    static esp_err_t update_fw_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen,
                                          uint8_t **outbuf, ssize_t *outlen, void *priv_data) {
        *outbuf = new uint8_t[sizeof(_ota_update_response)];
        ota_update(OTA_METHOD_PROTOCOMM, (void*)inbuf, inlen, *outbuf, sizeof(_ota_update_response), (size_t*)outlen);
    }


    void start_provisioning() {
        char service_name[18];
        get_device_service_name(service_name, sizeof(service_name));
        wifi_prov_security_t security = WIFI_PROV_SECURITY_0;

        // todo: what to do about pop key

        const char *pop = "abcd1234";
        const char *service_key = NULL;

        uint8_t custom_service_uuid[] = {
            /* LSB <---------------------------------------
             * ---------------------------------------> MSB */
            0xb4, 0xdf, 0x5a, 0x1c, 0x3f, 0x6b, 0xf4, 0xbf,
            0xea, 0x4a, 0x82, 0x03, 0x04, 0x90, 0x1a, 0x02,
        };

        wifi_prov_scheme_ble_set_service_uuid(custom_service_uuid);
        wifi_prov_mgr_endpoint_create("serial-no");
        wifi_prov_mgr_endpoint_create("provision-key");

        ESP_LOGI(TAG, "Provision manager started");
        ESP_ERROR_CHECK(wifi_prov_mgr_start_provisioning(security, NULL, service_name, NULL));

        wifi_prov_mgr_endpoint_register("serial-no", get_serial_no_handler, NULL);
        wifi_prov_mgr_endpoint_register("provision-key", set_provision_key_handler, NULL);
        wifi_prov_mgr_endpoint_register("fw-version", fw_version_handler, NULL);
        wifi_prov_mgr_endpoint_register("update-fw", update_fw_handler, NULL);

    }
};

class StandardWifiHandler : public WifiHandler {
private:
    bool _provisioned_before = false;
public:
    StandardWifiHandler(bool just_provisioned) : _provisioned_before(just_provisioned) {
        if(!_provisioned_before) {
            ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
            ESP_ERROR_CHECK(esp_wifi_start());
        }
    }

    ~StandardWifiHandler() {
        vTaskDelete(_task);
    }

    void init() override {
        _task = create_task_with_watchdog(task_function, "WiFi", 4096, this, tskIDLE_PRIORITY);
    }


    virtual void wifi_event_start() override {
        connect_to_wifi();
    }

private:
    void connect_to_wifi() {        
        wifi_config_t conf;
        esp_wifi_get_config(WIFI_IF_STA, &conf);

        ESP_LOGI(TAG, "Connecting to %s", (const char*)conf.sta.ssid);
        ESP_LOGI(TAG, "Connect result %d", esp_wifi_connect());
    }

    void task() {
        while(true) {
            if(wifi_wait_for_disconnect(pdMS_TO_TICKS(5000))) {
                vTaskDelay(pdMS_TO_TICKS(5000));
                this->connect_to_wifi();
            }
            esp_task_wdt_reset();
            vTaskDelay(pdMS_TO_TICKS(5000));
        }
    }

    static void task_function(void* p1) {
        StandardWifiHandler* inst = (StandardWifiHandler*)p1;
        assert(inst != nullptr);
        inst->task();
    }

    TaskHandle_t _task = {0};
};



extern "C" {
    void wifi_init_early() {
        // Init stuff that must be done early in the init process
        WifiStateSupervisor::get().init_early();
    }

    void wifi_init() {
        ESP_ERROR_CHECK(esp_netif_init());
        esp_netif_t* sta = esp_netif_create_default_wifi_sta();
        assert(sta != nullptr);

        wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
        ESP_ERROR_CHECK(esp_wifi_init(&cfg));

        // Init wifi
        WifiStateSupervisor::get().init();

        // Wait for WiFi to connect and sync time
        while(!wifi_is_connected()) {
            vTaskDelay(pdMS_TO_TICKS(5000));
            esp_task_wdt_reset();
        }
        get_sntp_time();
    }

    EventGroupHandle_t wifi_event_group() {
        return WifiStateSupervisor::get().event_group();
    }

    bool wifi_wait_for_connection(TickType_t ticks_to_wait) {
        return WifiStateSupervisor::get().wait_for_event(WIFI_BIT_CONNECTED, ticks_to_wait);
    }

    bool wifi_wait_for_disconnect(TickType_t ticks_to_wait) {
        return WifiStateSupervisor::get().wait_for_event(WIFI_BIT_DISCONNECTED, ticks_to_wait);
    }
    
    bool wifi_is_connected() {
        return WifiStateSupervisor::get().is_connected();
    }

    const wifi_info_t* wifi_get_info() {
        return WifiStateSupervisor::get().wifi_info();
    }
}

WifiStateSupervisor WifiStateSupervisor::_instance;

void WifiStateSupervisor::init() {
    // clear out padding (otherwise reading SN will sometimes return junk)
    _wifi_info.sn.bytes._pad[0] = 0;
    _wifi_info.sn.bytes._pad[1] = 0;

    // Get MAC address and store it in wifi_info
    esp_efuse_mac_get_default(_wifi_info.sn.bytes.mac);

    _wifi_handler = new ProvisioningWifiHandler();

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, event_dispatcher, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, event_dispatcher, NULL));

    _wifi_handler->init();

}

void WifiStateSupervisor::start_provisioning() {
    if(_wifi_handler) {
        delete _wifi_handler;
        _wifi_handler = new ProvisioningWifiHandler();
        _wifi_handler->init();
    }
}

void WifiStateSupervisor::switch_to_standard(bool just_provisioned) {
    delete _wifi_handler;
    _wifi_handler = new StandardWifiHandler(just_provisioned);
    _wifi_handler->init();

    // Fire provision complete event
    event_post(SYSTEM_EVENT_BASE, SYSTEM_EVENT_PROVISION_COMPLETE, nullptr, 0, pdMS_TO_TICKS(1000));
}
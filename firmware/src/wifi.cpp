extern "C" {
#include "wifi.h"
#include "network.h"
#include "pill_gpio.h"
#include "util.h"
#include "rtc_sntp.h"
#include "sdkconfig.h"

#include <esp_wifi.h>
#include <esp_event.h>
#include <esp_err.h>
#include <esp_log.h>
#include <esp_mac.h>
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

protected:
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


class StandardWifiHandler : public WifiHandler {
public:
    StandardWifiHandler() {}

    ~StandardWifiHandler() {
        vTaskDelete(_task);
    }

    void init() override {
        // Set WiFi mode and start
        ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
        ESP_ERROR_CHECK(esp_wifi_start());
        
        // Create WiFi reconnection task
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
        esp_err_t status = esp_wifi_connect();
        ESP_LOGI(TAG, "Connect result %d", status);
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

    esp_err_t wifi_set_credentials(const char* ssid, const char* password) {
        wifi_config_t wifi_config = {};
        
        if(strlen(ssid) > sizeof(wifi_config.sta.ssid) - 1) {
            return ESP_ERR_INVALID_ARG;
        }
        if(strlen(password) > sizeof(wifi_config.sta.password) - 1) {
            return ESP_ERR_INVALID_ARG;
        }
        
        strncpy((char*)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid) - 1);
        strncpy((char*)wifi_config.sta.password, password, sizeof(wifi_config.sta.password) - 1);
        
        ESP_LOGI(TAG, "Setting WiFi credentials for SSID: %s", ssid);
        esp_err_t err = esp_wifi_set_config(WIFI_IF_STA, &wifi_config);
        
        if(err == ESP_OK) {
            // Trigger reconnection with new credentials
            ESP_LOGI(TAG, "Reconnecting to WiFi with new credentials");
            esp_wifi_disconnect();
            esp_wifi_connect();
        }
        
        return err;
    }
}

WifiStateSupervisor WifiStateSupervisor::_instance;

void WifiStateSupervisor::init() {
    // Get MAC address and store it in wifi_info
    esp_efuse_mac_get_default(_wifi_info.sn.bytes.mac);

    // Configure WiFi with hardcoded credentials
    // TODO: Replace with BLE provisioning service to receive credentials
    #ifdef CONFIG_DEV_WIFI_ENABLED
    wifi_config_t wifi_config = {};
    strcpy((char*)wifi_config.sta.ssid, CONFIG_DEV_WIFI_SSID);
    strcpy((char*)wifi_config.sta.password, CONFIG_DEV_WIFI_PASSWORD);
    
    ESP_LOGI(TAG, "Configuring WiFi with hardcoded credentials: %s", wifi_config.sta.ssid);
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    #else
    ESP_LOGW(TAG, "No WiFi credentials configured - waiting for BLE provisioning");
    #endif

    // Create standard WiFi handler
    _wifi_handler = new StandardWifiHandler();

    // Register event handlers
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, event_dispatcher, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, event_dispatcher, NULL));

    _wifi_handler->init();
}
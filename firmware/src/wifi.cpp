extern "C" {
#include "wifi.h"
#include "network.h"
#include "util.h"
#include "rtc_sntp.h"
#include "sdkconfig.h"

#include <esp_wifi.h>
#include <esp_event.h>
#include <esp_err.h>
#include <esp_log.h>
#include <esp_mac.h>
#include <esp_timer.h>

#include <wifi_provisioning/manager.h>
#include <wifi_provisioning/scheme_ble.h>
#include <cJSON.h>
}

#include "event.h"

#define TAG "Newifi"

// Handler for device_serial custom provisioning endpoint
// Returns JSON with device serial number in format: ESP32-{MAC address}
static esp_err_t device_serial_handler(uint32_t session_id,
                                       const uint8_t *inbuf, ssize_t inlen,
                                       uint8_t **outbuf, ssize_t *outlen,
                                       void *priv_data)
{
    // Get the MAC address from wifi info
    const wifi_info_t* wifi_info = wifi_get_info();
    
    // Build full serial number: ESP32-{MAC in uppercase hex}
    char serial_number[32];
    snprintf(serial_number, sizeof(serial_number), "ESP32-%02X%02X%02X%02X%02X%02X",
             wifi_info->sn.bytes.mac[0],
             wifi_info->sn.bytes.mac[1],
             wifi_info->sn.bytes.mac[2],
             wifi_info->sn.bytes.mac[3],
             wifi_info->sn.bytes.mac[4],
             wifi_info->sn.bytes.mac[5]);
    
    // Create JSON response
    cJSON *response = cJSON_CreateObject();
    if (!response) {
        ESP_LOGE(TAG, "Failed to create JSON response for device_serial");
        return ESP_FAIL;
    }
    
    cJSON_AddStringToObject(response, "serialNumber", serial_number);
    
    // Serialize JSON to string
    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    
    if (!json_string) {
        ESP_LOGE(TAG, "Failed to serialize device_serial JSON");
        return ESP_FAIL;
    }
    
    // Allocate output buffer and copy response
    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) {
        ESP_LOGE(TAG, "Failed to allocate memory for device_serial response");
        free(json_string);
        return ESP_ERR_NO_MEM;
    }
    
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    
    ESP_LOGI(TAG, "device_serial endpoint: %s", serial_number);
    
    free(json_string);
    return ESP_OK;
}

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
        // WiFi mode and start are managed by WifiStateSupervisor::init().
        // Just launch the reconnect task.
        _task = create_task_with_watchdog(task_function, "WiFi", 4096, this, tskIDLE_PRIORITY);
    }

    virtual void wifi_event_start() override {
        reset_reconnect_backoff();
        connect_to_wifi();
    }

private:
    // Exponential backoff for WiFi reconnection attempts
    uint32_t _reconnect_attempt = 0;
    uint32_t _last_disconnect_time = 0;

    uint32_t get_reconnect_delay_ms() {
        // Exponential backoff: 5s → 10s → 30s → 1m → 5m (repeat)
        switch(_reconnect_attempt) {
            case 0: return 5000;   // 10 seconds
            case 1: return 10000;   // 30 seconds
            case 3: return 30000;   // 1 minute
            case 4: return 60000;   // 1 minute
            default: return 300000; // 5 minutes (max) - repeat indefinitely
        }
    }

    void reset_reconnect_backoff() {
        _reconnect_attempt = 0;
    }

    void connect_to_wifi() {        
        wifi_config_t conf;
        esp_wifi_get_config(WIFI_IF_STA, &conf);

        ESP_LOGI(TAG, "Connecting to %s (attempt %lu)", (const char*)conf.sta.ssid, _reconnect_attempt + 1);
        esp_err_t status = esp_wifi_connect();
        ESP_LOGI(TAG, "Connect result %d", status);
    }

    void task() {
        while(true) {
            if(wifi_wait_for_disconnect(pdMS_TO_TICKS(5000))) {
                // WiFi disconnected - start exponential backoff reconnection attempts
                _last_disconnect_time = esp_timer_get_time() / 1000000; // Current time in seconds
                _reconnect_attempt = 0;
                ESP_LOGI(TAG, "WiFi lost - will attempt periodic reconnection with exponential backoff");
            }

            // If WiFi is disconnected, attempt reconnection with backoff
            if(!WifiStateSupervisor::get().is_connected()) {
                uint32_t delay_ms = get_reconnect_delay_ms();
                // Wait for either connection or timeout
                if(!wifi_wait_for_connection(pdMS_TO_TICKS(delay_ms))) {
                    // Still not connected after delay - increment attempts and retry
                    _reconnect_attempt++;
                    uint32_t time_since_disconnect = (esp_timer_get_time() / 1000000) - _last_disconnect_time;
                    ESP_LOGI(TAG, "WiFi reconnect attempt #%lu after %lus", _reconnect_attempt, time_since_disconnect);
                    this->connect_to_wifi();
                }
            }

            esp_task_wdt_reset();
            vTaskDelay(pdMS_TO_TICKS(1000));
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
        // Deprecated - credentials are set via wifi_provisioning BLE
        return ESP_OK;
    }
}

WifiStateSupervisor WifiStateSupervisor::_instance;

void WifiStateSupervisor::init() {
    esp_efuse_mac_get_default(_wifi_info.sn.bytes.mac);

    // Register WiFi and IP event handlers
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, event_dispatcher, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, event_dispatcher, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_LOST_IP, event_dispatcher, NULL));

    // Initialize WiFi handler before any WiFi operations (needed for event callbacks)
    _wifi_handler = new StandardWifiHandler();

    // ESP unified provisioning over BLE
    wifi_prov_mgr_config_t prov_config;
    memset(&prov_config, 0, sizeof(prov_config));
    prov_config.scheme = wifi_prov_scheme_ble;
    prov_config.scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM;
    
    ESP_ERROR_CHECK(wifi_prov_mgr_init(prov_config));
    
    // Create custom endpoint for device serial number (must be created before start_provisioning)
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("device_serial"));

    bool provisioned = false;
    ESP_ERROR_CHECK(wifi_prov_mgr_is_provisioned(&provisioned));

    if (!provisioned) {
        // Build BLE device name from last 3 bytes of MAC
        char service_name[20];
        snprintf(service_name, sizeof(service_name), "PILL-%02X%02X%02X",
                 _wifi_info.sn.bytes.mac[3],
                 _wifi_info.sn.bytes.mac[4],
                 _wifi_info.sn.bytes.mac[5]);

        ESP_LOGI(TAG, "WiFi not provisioned - starting BLE provisioning as: %s", service_name);

        // Security 1 with no proof-of-possession (NULL)
        ESP_ERROR_CHECK(wifi_prov_mgr_start_provisioning(
            WIFI_PROV_SECURITY_1, NULL, service_name, NULL));
        
        // Register handler for device_serial endpoint (must be registered after start_provisioning)
        ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register(
            "device_serial", device_serial_handler, NULL));

        // Block until provisioning completes and WiFi connects
        wifi_prov_mgr_wait();
        wifi_prov_mgr_deinit();
        // WiFi is already running in STA mode and connected at this point
        ESP_LOGI(TAG, "BLE provisioning complete");
    } else {
        // Already provisioned - deinit prov manager and start WiFi normally
        wifi_prov_mgr_deinit();
        ESP_LOGI(TAG, "WiFi already provisioned, starting STA");
        ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
        ESP_ERROR_CHECK(esp_wifi_start());
        // WIFI_EVENT_STA_START fires -> StandardWifiHandler::wifi_event_start() -> esp_wifi_connect()
    }

    // Start reconnect watchdog task
    _wifi_handler->init();
}
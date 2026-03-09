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

// Timeout for waiting on claim credentials (in seconds)
// 2 minutes gives app time to claim device on control plane
// Watchdog (120s) provides absolute safety limit for any blocked operation
#define CLAIM_CREDENTIALS_TIMEOUT_SEC 120

// Global flags and storage for provisioning flow
static bool device_serial_acknowledged = false;
static char claim_id[128] = {0};
static char claim_token[256] = {0};
static bool claim_credentials_received = false;
static fleet_prov_status_t fleet_prov_status = FLEET_PROV_STATUS_IDLE;

// Handler for device_serial custom provisioning endpoint
// Returns JSON with device serial number in format: ESP32-{MAC address}
static esp_err_t device_serial_handler(uint32_t session_id,
                                       const uint8_t *inbuf, ssize_t inlen,
                                       uint8_t **outbuf, ssize_t *outlen,
                                       void *priv_data)
{
    ESP_LOGI(TAG, "=== device_serial_handler CALLED ===");
    ESP_LOGI(TAG, "Session ID: %lu, Input length: %zd", session_id, inlen);
    
    // Get the MAC address from wifi info
    const wifi_info_t* wifi_info = wifi_get_info();
    if (!wifi_info) {
        ESP_LOGE(TAG, "Failed to get wifi_info");
        return ESP_FAIL;
    }
    ESP_LOGI(TAG, "Got wifi_info, MAC: %02X:%02X:%02X:%02X:%02X:%02X",
             wifi_info->sn.bytes.mac[0],
             wifi_info->sn.bytes.mac[1],
             wifi_info->sn.bytes.mac[2],
             wifi_info->sn.bytes.mac[3],
             wifi_info->sn.bytes.mac[4],
             wifi_info->sn.bytes.mac[5]);
    
    // Build full serial number: ESP32-{MAC in uppercase hex}
    char serial_number[32];
    snprintf(serial_number, sizeof(serial_number), "ESP32-%02X%02X%02X%02X%02X%02X",
             wifi_info->sn.bytes.mac[0],
             wifi_info->sn.bytes.mac[1],
             wifi_info->sn.bytes.mac[2],
             wifi_info->sn.bytes.mac[3],
             wifi_info->sn.bytes.mac[4],
             wifi_info->sn.bytes.mac[5]);
    ESP_LOGI(TAG, "Built serial number: %s", serial_number);
    
    // Create JSON response
    cJSON *response = cJSON_CreateObject();
    if (!response) {
        ESP_LOGE(TAG, "Failed to create JSON response for device_serial");
        return ESP_FAIL;
    }
    ESP_LOGI(TAG, "JSON object created successfully");
    
    cJSON_AddStringToObject(response, "serialNumber", serial_number);
    ESP_LOGI(TAG, "Added serialNumber to JSON");
    
    // Serialize JSON to string
    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    
    if (!json_string) {
        ESP_LOGE(TAG, "Failed to serialize device_serial JSON");
        return ESP_FAIL;
    }
    ESP_LOGI(TAG, "Serialized JSON: %s", json_string);
    
    // Allocate output buffer and copy response
    size_t response_len = strlen(json_string);
    ESP_LOGI(TAG, "Response length: %zu bytes", response_len);
    
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) {
        ESP_LOGE(TAG, "Failed to allocate memory for device_serial response (%zu bytes)", response_len);
        free(json_string);
        return ESP_ERR_NO_MEM;
    }
    ESP_LOGI(TAG, "Output buffer allocated");
    
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    ESP_LOGI(TAG, "Response copied to output buffer, outlen set to %zd", *outlen);
    
    ESP_LOGI(TAG, "=== device_serial_handler SUCCESS: %s ===", serial_number);
    
    free(json_string);
    return ESP_OK;
}

// Handler for device_serial_ack custom provisioning endpoint
// Called by app to acknowledge receipt of serial number
static esp_err_t device_serial_ack_handler(uint32_t session_id,
                                           const uint8_t *inbuf, ssize_t inlen,
                                           uint8_t **outbuf, ssize_t *outlen,
                                           void *priv_data)
{
    ESP_LOGI(TAG, "=== device_serial_ack_handler CALLED ===");
    ESP_LOGI(TAG, "Session ID: %lu, Input length: %zd (app acknowledged receipt)", session_id, inlen);
    
    // Mark that app received the serial number
    device_serial_acknowledged = true;
    ESP_LOGI(TAG, "Device serial acknowledgement received - app has serial number");
    
    // Create simple JSON response
    cJSON *response = cJSON_CreateObject();
    if (!response) {
        ESP_LOGE(TAG, "Failed to create JSON response for device_serial_ack");
        return ESP_FAIL;
    }
    
    cJSON_AddBoolToObject(response, "acknowledged", true);
    
    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    
    if (!json_string) {
        ESP_LOGE(TAG, "Failed to serialize device_serial_ack JSON");
        return ESP_FAIL;
    }
    
    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) {
        ESP_LOGE(TAG, "Failed to allocate memory for device_serial_ack response");
        free(json_string);
        return ESP_ERR_NO_MEM;
    }
    
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    
    ESP_LOGI(TAG, "=== device_serial_ack_handler SUCCESS ===");
    
    free(json_string);
    return ESP_OK;
}

// Handler for device_claim_token_set custom provisioning endpoint
// Called by app to provide claimId and claimToken after claim is made on control plane
static esp_err_t device_claim_token_set_handler(uint32_t session_id,
                                                const uint8_t *inbuf, ssize_t inlen,
                                                uint8_t **outbuf, ssize_t *outlen,
                                                void *priv_data)
{
    ESP_LOGI(TAG, "=== device_claim_token_set_handler CALLED ===");
    ESP_LOGI(TAG, "Session ID: %lu, Input length: %zd", session_id, inlen);
    
    if (!inbuf || inlen <= 0) {
        ESP_LOGE(TAG, "Invalid input buffer for claim token");
        return ESP_FAIL;
    }
    
    // Parse incoming JSON: {"claimId":"<value>","claimToken":"<value>"}
    // Create a null-terminated string from the input buffer
    char json_buffer[512];
    if (inlen >= sizeof(json_buffer)) {
        ESP_LOGE(TAG, "Input buffer too large: %zd", inlen);
        return ESP_FAIL;
    }
    memcpy(json_buffer, inbuf, inlen);
    json_buffer[inlen] = '\0';
    
    ESP_LOGI(TAG, "Received JSON: %s", json_buffer);
    
    cJSON *received = cJSON_Parse(json_buffer);
    if (!received) {
        ESP_LOGE(TAG, "Failed to parse claim token JSON");
        return ESP_FAIL;
    }
    
    // Extract claimId
    cJSON *claim_id_item = cJSON_GetObjectItem(received, "claimId");
    if (!claim_id_item || !claim_id_item->valuestring) {
        ESP_LOGE(TAG, "Missing claimId in request");
        cJSON_Delete(received);
        return ESP_FAIL;
    }
    
    // Extract claimToken
    cJSON *claim_token_item = cJSON_GetObjectItem(received, "claimToken");
    if (!claim_token_item || !claim_token_item->valuestring) {
        ESP_LOGE(TAG, "Missing claimToken in request");
        cJSON_Delete(received);
        return ESP_FAIL;
    }
    
    // Store credentials
    strncpy(claim_id, claim_id_item->valuestring, sizeof(claim_id) - 1);
    strncpy(claim_token, claim_token_item->valuestring, sizeof(claim_token) - 1);
    claim_credentials_received = true;
    
    ESP_LOGI(TAG, "=== CLAIM CREDENTIALS RECEIVED ===");
    ESP_LOGI(TAG, "claimId:    %s", claim_id);
    ESP_LOGI(TAG, "claimToken: %s", claim_token);
    ESP_LOGI(TAG, "==============================");
    cJSON_Delete(received);
    
    // Create response
    cJSON *response = cJSON_CreateObject();
    if (!response) {
        ESP_LOGE(TAG, "Failed to create JSON response for claim token");
        return ESP_FAIL;
    }
    
    cJSON_AddBoolToObject(response, "received", true);
    
    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    
    if (!json_string) {
        ESP_LOGE(TAG, "Failed to serialize claim token response JSON");
        return ESP_FAIL;
    }
    
    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) {
        ESP_LOGE(TAG, "Failed to allocate memory for claim token response");
        free(json_string);
        return ESP_ERR_NO_MEM;
    }
    
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
    
    ESP_LOGI(TAG, "=== device_claim_token_set_handler SUCCESS ===");
    
    free(json_string);
    return ESP_OK;
}

// Handler for fleet_provisioning_status custom endpoint
// App polls this every few seconds to check if device completed Fleet Provisioning
static esp_err_t fleet_provisioning_status_handler(uint32_t session_id,
                                                    const uint8_t *inbuf, ssize_t inlen,
                                                    uint8_t **outbuf, ssize_t *outlen,
                                                    void *priv_data)
{
    const char* status_str;
    switch (fleet_prov_status) {
        case FLEET_PROV_STATUS_PENDING: status_str = "pending"; break;
        case FLEET_PROV_STATUS_SUCCESS: status_str = "success"; break;
        case FLEET_PROV_STATUS_FAILED:  status_str = "failed";  break;
        default:                        status_str = "idle";    break;
    }
    ESP_LOGI(TAG, "=== fleet_provisioning_status_handler: %s ===", status_str);

    cJSON *response = cJSON_CreateObject();
    if (!response) return ESP_FAIL;
    cJSON_AddStringToObject(response, "status", status_str);

    char *json_string = cJSON_PrintUnformatted(response);
    cJSON_Delete(response);
    if (!json_string) return ESP_FAIL;

    size_t response_len = strlen(json_string);
    *outbuf = (uint8_t *)malloc(response_len);
    if (!*outbuf) {
        free(json_string);
        return ESP_ERR_NO_MEM;
    }
    memcpy(*outbuf, json_string, response_len);
    *outlen = response_len;
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

    bool wifi_device_serial_acknowledged() {
        return device_serial_acknowledged;
    }

    void wifi_reset_serial_acknowledgement() {
        device_serial_acknowledged = false;
        ESP_LOGI(TAG, "Device serial acknowledgement flag reset");
    }

    bool wifi_claim_credentials_received() {
        return claim_credentials_received;
    }

    void wifi_get_claim_credentials(char *claim_id_out, size_t claim_id_len,
                                     char *claim_token_out, size_t claim_token_len) {
        if (claim_id_out && claim_id_len > 0) {
            strncpy(claim_id_out, claim_id, claim_id_len - 1);
            claim_id_out[claim_id_len - 1] = '\0';
        }
        if (claim_token_out && claim_token_len > 0) {
            strncpy(claim_token_out, claim_token, claim_token_len - 1);
            claim_token_out[claim_token_len - 1] = '\0';
        }
    }

    void wifi_reset_claim_credentials() {
        memset(claim_id, 0, sizeof(claim_id));
        memset(claim_token, 0, sizeof(claim_token));
        claim_credentials_received = false;
        ESP_LOGI(TAG, "Claim credentials reset");
    }

    fleet_prov_status_t wifi_get_fleet_provisioning_status() {
        return fleet_prov_status;
    }

    void wifi_set_fleet_provisioning_status(fleet_prov_status_t status) {
        fleet_prov_status = status;
        const char* str;
        switch (status) {
            case FLEET_PROV_STATUS_PENDING: str = "PENDING"; break;
            case FLEET_PROV_STATUS_SUCCESS: str = "SUCCESS"; break;
            case FLEET_PROV_STATUS_FAILED:  str = "FAILED";  break;
            default:                        str = "IDLE";    break;
        }
        ESP_LOGI(TAG, "Fleet provisioning status: %s", str);
    }

    void wifi_deinit_provisioning() {
        ESP_LOGI(TAG, "Shutting down BLE provisioning manager...");
        wifi_prov_mgr_deinit();
        ESP_LOGI(TAG, "BLE provisioning manager deinitialized");
    }

    // WiFi provisioning manager event handler callback
    // Called by the provisioning manager for provisioning state changes
    static void wifi_prov_event_handler(void *user_data, wifi_prov_cb_event_t event, void *event_data) {
        switch (event) {
            case WIFI_PROV_CRED_RECV:
                ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_CRED_RECV - WiFi credentials received from app");
                break;
            case WIFI_PROV_CRED_SUCCESS:
                ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_CRED_SUCCESS - Device successfully connected to WiFi");
                // At this point, WiFi is connected and provisioning manager stays active (auto-stop disabled)
                ESP_LOGI(TAG, "✓ WiFi connected - BLE staying open for claim credentials and fleet provisioning");
                break;
            case WIFI_PROV_CRED_FAIL:
                ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_CRED_FAIL - Failed to connect to WiFi");
                break;
            case WIFI_PROV_START:
                ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_START");
                break;
            case WIFI_PROV_END:
                ESP_LOGI(TAG, "Provisioning event: WIFI_PROV_END");
                break;
            default:
                break;
        }
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
    prov_config.app_event_handler = {
        .event_cb = wifi_prov_event_handler,
        .user_data = NULL
    };
    
    ESP_ERROR_CHECK(wifi_prov_mgr_init(prov_config));
    
    // Disable auto-stop so BLE stays alive during fleet provisioning
    // We'll manually call wifi_prov_mgr_stop_provisioning() when fleet provisioning completes
    ESP_ERROR_CHECK(wifi_prov_mgr_disable_auto_stop(1000));
    ESP_LOGI(TAG, "Auto-stop disabled - BLE will remain active for fleet provisioning");
    
    // Create custom endpoints for device serial number (must be created before start_provisioning)
    ESP_LOGI(TAG, "Creating device_serial endpoint...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("device_serial"));
    ESP_LOGI(TAG, "device_serial endpoint created successfully");
    
    ESP_LOGI(TAG, "Creating device_serial_ack endpoint...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("device_serial_ack"));
    ESP_LOGI(TAG, "device_serial_ack endpoint created successfully");
    
    ESP_LOGI(TAG, "Creating device_claim_token_set endpoint...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("device_claim_token_set"));
    ESP_LOGI(TAG, "device_claim_token_set endpoint created successfully");

    ESP_LOGI(TAG, "Creating fleet_provisioning_status endpoint...");
    ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("fleet_provisioning_status"));
    ESP_LOGI(TAG, "fleet_provisioning_status endpoint created successfully");

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
        
        // Register handlers for custom endpoints (must be registered after start_provisioning)
        ESP_LOGI(TAG, "Registering device_serial endpoint handler...");
        ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register(
            "device_serial", device_serial_handler, NULL));
        ESP_LOGI(TAG, "device_serial endpoint handler registered successfully");
        
        ESP_LOGI(TAG, "Registering device_serial_ack endpoint handler...");
        ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register(
            "device_serial_ack", device_serial_ack_handler, NULL));
        ESP_LOGI(TAG, "device_serial_ack endpoint handler registered successfully");
        
        ESP_LOGI(TAG, "Registering device_claim_token_set endpoint handler...");
        ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register(
            "device_claim_token_set", device_claim_token_set_handler, NULL));
        ESP_LOGI(TAG, "device_claim_token_set endpoint handler registered successfully");

        ESP_LOGI(TAG, "Registering fleet_provisioning_status endpoint handler...");
        ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register(
            "fleet_provisioning_status", fleet_provisioning_status_handler, NULL));
        ESP_LOGI(TAG, "fleet_provisioning_status endpoint handler registered successfully");

        // Wait for app to send claim credentials (claimId and claimToken) via BLE endpoint
        // WiFi connect success is detected via provisioning event callback
        // BLE stays open because auto-stop is disabled
        int credentials_wait_sec = 0;
        while (!wifi_claim_credentials_received() && credentials_wait_sec < CLAIM_CREDENTIALS_TIMEOUT_SEC) {
            vTaskDelay(pdMS_TO_TICKS(1000));
            credentials_wait_sec++;
            
            if (credentials_wait_sec % 15 == 0) {
                ESP_LOGW(TAG, "⏳ Still waiting for claim credentials from app... (%d/%d sec)", 
                         credentials_wait_sec, CLAIM_CREDENTIALS_TIMEOUT_SEC);
            }
            esp_task_wdt_reset();
        }
        
        // Check if credentials were received successfully
        if (wifi_claim_credentials_received()) {
            ESP_LOGI(TAG, "✓ Claim credentials received after %d sec", credentials_wait_sec);
            ESP_LOGI(TAG, "✓ BLE open for fleet provisioning status polling");
            
            // Mark as pending - BLE remains open so app can poll fleet_provisioning_status
            fleet_prov_status = FLEET_PROV_STATUS_PENDING;
            // Do NOT deinit BLE here - wifi_deinit_provisioning() called by fleet_provisioning_task
        } else {
            // Timeout occurred - claim credentials never received
            ESP_LOGE(TAG, "✗ TIMEOUT: Claim credentials not received within %d sec", CLAIM_CREDENTIALS_TIMEOUT_SEC);
            ESP_LOGE(TAG, "App did not send claim request via BLE endpoint");
            ESP_LOGE(TAG, "Clearing WiFi credentials and restarting device...");
            
            // Clear all provisioning state
            wifi_reset_claim_credentials();
            wifi_prov_mgr_deinit();
            esp_wifi_restore();
            
            vTaskDelay(pdMS_TO_TICKS(1000));
            esp_restart();
        }
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
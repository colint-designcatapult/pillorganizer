#include "network.h"
#include <esp_log.h>
#include <esp_wifi.h>
#include <esp_netif.h>
#include <esp_err.h>
#include "wifi_provision.h"
#include "supervisor.h"
#include "claim.h"



#define TAG "NETWORK"

static void network_wifi_event_handler(void* arg, esp_event_base_t event_base,
                               int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        // When the Wi-Fi driver starts, initiate the connection
        ESP_LOGI(TAG, "Wi-Fi started, connecting to AP...");
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        // If disconnected (or failed to connect), try to connect again
        ESP_LOGW(TAG, "Disconnected from AP. Attempting to reconnect...");
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_NETIF_DISCONNECTED));
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_CONNECTED) {
        // If disconnected (or failed to connect), try to connect again
        ESP_LOGW(TAG, "Connected to AP");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        // Once connected and an IP is assigned, print it out
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "Successfully connected! Got IP: " IPSTR, IP2STR(&event->ip_info.ip));
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_NETIF_CONNECTED));
    }
}

static void network_wifi_init()
{
    // Initialize the underlying TCP/IP stack (LwIP)
    ESP_ERROR_CHECK(esp_netif_init());

    // Create the default Wi-Fi Station network interface
    esp_netif_t *sta_netif = esp_netif_create_default_wifi_sta();
    assert(sta_netif);  

    // Initialize the Wi-Fi driver with default parameters
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &network_wifi_event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &network_wifi_event_handler, NULL));

    // Set the Wi-Fi operating mode to Station (STA)
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));

    // Start the Wi-Fi driver
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "WiFi interface initialized");
}

void network_init()
{    
    // Initialize/start wifi
    network_wifi_init();
}

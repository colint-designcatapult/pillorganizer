#include "network.h"
#include <esp_log.h>
#include <esp_netif.h>
#include <esp_err.h>
#include <esp_event.h>
#include "supervisor.h"
#include "sdkconfig.h"

#if !CONFIG_EMULATOR_MODE
#include <esp_wifi.h>
#include "wifi_provision.h"
#include "claim.h"
#endif

#if CONFIG_EMULATOR_MODE
#include <esp_eth.h>
#endif

#define TAG "NETWORK"

#if CONFIG_EMULATOR_MODE
/* -----------------------------------------------------------------
 * Ethernet networking for the QEMU emulator
 *
 * The Espressif QEMU emulator provides an OpenCores Ethernet MAC that
 * is accessed via the esp_eth driver with CONFIG_ETH_USE_OPENETH.
 * DHCP runs on top of the emulated Ethernet interface.
 * ----------------------------------------------------------------- */

static void network_eth_event_handler(void *arg, esp_event_base_t event_base,
                                      int32_t event_id, void *event_data)
{
    if (event_base == ETH_EVENT) {
        switch (event_id) {
            case ETHERNET_EVENT_CONNECTED:
                ESP_LOGI(TAG, "Ethernet link up");
                break;
            case ETHERNET_EVENT_DISCONNECTED:
                ESP_LOGW(TAG, "Ethernet link down");
                ESP_ERROR_CHECK(supervisor_submit_event(EVENT_NETIF_DISCONNECTED));
                break;
            default:
                break;
        }
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_ETH_GOT_IP) {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;
        ESP_LOGI(TAG, "Got IP via Ethernet: " IPSTR, IP2STR(&event->ip_info.ip));
        ESP_LOGI(TAG, "Access engineering interface at: http://" IPSTR, IP2STR(&event->ip_info.ip));
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_NETIF_CONNECTED));
    }
}

static void network_eth_init(void)
{
    ESP_ERROR_CHECK(esp_netif_init());

    esp_netif_config_t netif_cfg = ESP_NETIF_DEFAULT_ETH();
    esp_netif_t *eth_netif = esp_netif_new(&netif_cfg);
    if (!eth_netif) {
        ESP_LOGE(TAG, "Failed to create Ethernet netif");
        ESP_ERROR_CHECK(ESP_ERR_ESP_NETIF_INIT_FAILED);
    }

    eth_mac_config_t mac_config = ETH_MAC_DEFAULT_CONFIG();
    eth_phy_config_t phy_config = ETH_PHY_DEFAULT_CONFIG();

    esp_eth_mac_t *mac = esp_eth_mac_new_openeth(&mac_config);
    esp_eth_phy_t *phy = esp_eth_phy_new_dp83848(&phy_config);

    esp_eth_config_t eth_config = ETH_DEFAULT_CONFIG(mac, phy);
    esp_eth_handle_t eth_handle = NULL;
    ESP_ERROR_CHECK(esp_eth_driver_install(&eth_config, &eth_handle));
    ESP_ERROR_CHECK(esp_netif_attach(eth_netif, esp_eth_new_netif_glue(eth_handle)));

    ESP_ERROR_CHECK(esp_event_handler_register(ETH_EVENT, ESP_EVENT_ANY_ID,
                                               &network_eth_event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_ETH_GOT_IP,
                                               &network_eth_event_handler, NULL));

    ESP_ERROR_CHECK(esp_eth_start(eth_handle));

    ESP_LOGI(TAG, "Ethernet (OpenCores) interface initialized for QEMU emulator");
}

void network_init(void)
{
    network_eth_init();
}

void network_reconnect(void)
{
    /* Ethernet reconnection is handled automatically by the driver. */
    ESP_LOGI(TAG, "Ethernet reconnect: link-layer handles reconnection automatically");
}

#else /* !CONFIG_EMULATOR_MODE — real hardware Wi-Fi path */

static void network_wifi_event_handler(void* arg, esp_event_base_t event_base,
                               int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        // When the Wi-Fi driver starts, initiate the connection
        ESP_LOGI(TAG, "Wi-Fi started, connecting to AP...");
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        ESP_LOGW(TAG, "Disconnected from AP. Attempting to reconnect...");
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_NETIF_DISCONNECTED));
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_CONNECTED) {
        // If disconnected (or failed to connect), try to connect again
        ESP_LOGW(TAG, "Connected to AP");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        // Once connected and an IP is assigned, print it out
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "Successfully connected! Got IP: " IPSTR, IP2STR(&event->ip_info.ip));
        ESP_LOGI(TAG, "Access engineering interface at: http://" IPSTR, IP2STR(&event->ip_info.ip));
        ESP_ERROR_CHECK(supervisor_submit_event(EVENT_NETIF_CONNECTED));
    }
}

static void network_wifi_init()
{
    // Initialize the underlying TCP/IP stack (LwIP)
    ESP_ERROR_CHECK(esp_netif_init());

    // Create the default Wi-Fi Station network interface
    esp_netif_t *sta_netif = esp_netif_create_default_wifi_sta();
    if (!sta_netif) {
        ESP_LOGE(TAG, "Failed to create Wi-Fi Station network interface");
        ESP_ERROR_CHECK(ESP_ERR_ESP_NETIF_INIT_FAILED);
    }

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

void network_reconnect()
{
    esp_wifi_connect();
}

#endif /* CONFIG_EMULATOR_MODE */
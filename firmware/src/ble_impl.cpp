#include "ble_impl.h"
#include "network.h"
#include "wifi.h"
#include "esp_log.h"

#define TAG "PillBLE_Prov"

// Serial Number Characteristic - returns 6-byte MAC address
int SerialNumberCharacteristic::read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) {
    uint8_t serial_number[6];
    size_t len;
    
    network_get_serial_number(serial_number, &len);
    
    ESP_LOGI(TAG, "Serial Number read: %02X:%02X:%02X:%02X:%02X:%02X",
             serial_number[0], serial_number[1], serial_number[2],
             serial_number[3], serial_number[4], serial_number[5]);
    
    return os_mbuf_append(ctxt->om, serial_number, len);
}

// WiFi Credentials Characteristic - receives SSID\0PASSWORD
int WiFiCredentialsCharacteristic::write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) {
    uint8_t buffer[128];
    uint16_t len;
    
    // Receive data
    int err = ble_receive(ctxt->om, 0, sizeof(buffer), buffer, &len);
    if (err != 0) {
        ESP_LOGE(TAG, "Failed to receive WiFi credentials");
        return err;
    }
    
    // Parse format: SSID\0PASSWORD
    char* ssid = (char*)buffer;
    size_t ssid_len = strnlen(ssid, len);
    
    if (ssid_len >= len) {
        ESP_LOGE(TAG, "Invalid WiFi credentials format - no null terminator");
        return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
    }
    
    char* password = ssid + ssid_len + 1;
    size_t password_len = len - ssid_len - 1;
    
    if (password_len == 0) {
        ESP_LOGE(TAG, "Invalid WiFi credentials format - no password");
        return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
    }
    
    // Ensure null termination
    if (password[password_len - 1] != '\0') {
        if (password_len < sizeof(buffer) - ssid_len - 1) {
            password[password_len] = '\0';
        } else {
            ESP_LOGE(TAG, "Password too long");
            return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
        }
    }
    
    ESP_LOGI(TAG, "Received WiFi credentials - SSID: %s (password length: %d)", ssid, password_len);
    
    // Set WiFi credentials
    esp_err_t result = wifi_set_credentials(ssid, password);
    
    if (result != ESP_OK) {
        ESP_LOGE(TAG, "Failed to set WiFi credentials: %d", result);
        return BLE_ATT_ERR_UNLIKELY;
    }
    
    ESP_LOGI(TAG, "WiFi credentials set successfully");
    return 0;
}

// Certificate Characteristic - receives 16-byte certificate/OOB key
int CertificateCharacteristic::write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) {
    uint8_t buffer[16];
    uint16_t len;
    
    // Receive exactly 16 bytes
    int err = ble_receive(ctxt->om, 16, 16, buffer, &len);
    if (err != 0) {
        ESP_LOGE(TAG, "Failed to receive certificate - expected 16 bytes");
        return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
    }
    
    ESP_LOGI(TAG, "Received certificate (%d bytes)", len);
    
    // Store certificate
    esp_err_t result = network_set_certificate(buffer, len);
    
    if (result != ESP_OK) {
        ESP_LOGE(TAG, "Failed to store certificate: %d", result);
        return BLE_ATT_ERR_UNLIKELY;
    }
    
    ESP_LOGI(TAG, "Certificate stored successfully");
    return 0;
}



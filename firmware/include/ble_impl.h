#pragma once
#include "ble.h"

// BLE Provisioning Service
// Handles WiFi credential exchange and certificate provisioning

// Serial Number Characteristic (read-only)
// Returns 6-byte MAC address as device serial number
using SerialNumberCharacteristicUUID = BleUUID128<0x01,0x00,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class SerialNumberCharacteristic : public BaseGattCharacteristic<SerialNumberCharacteristicUUID> {
protected:
    int read(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override;

    bool readable() override {
        return true;
    }
};

// WiFi Credentials Characteristic (write-only)
// Format: SSID\0PASSWORD (null-terminated SSID followed by password)
using WiFiCredentialsCharacteristicUUID = BleUUID128<0x02,0x00,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class WiFiCredentialsCharacteristic : public BaseGattCharacteristic<WiFiCredentialsCharacteristicUUID> {
protected:
    int write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override;

    bool writable() override {
        return true;
    }
};

// Certificate Characteristic (write-only)
// Receives 16-byte OOB key/certificate for AWS IoT authentication
using CertificateCharacteristicUUID = BleUUID128<0x03,0x00,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                            0x5B,0x76,0xD8,0xDE,0x20>;
class CertificateCharacteristic : public BaseGattCharacteristic<CertificateCharacteristicUUID> {
protected:
    int write(uint16_t conn_handle, uint16_t attr_handle, struct ble_gatt_access_ctxt* ctxt) override;

    bool writable() override {
        return true;
    }
};

// Provisioning Service - combines all three characteristics
using ProvisioningServiceUUID = BleUUID128<0x00,0x00,0x9D,0xAE,0x9D,0x75,0x4C,0x35,0xB8,0x06,0xF8,
                                                0x5B,0x76,0xD8,0xDE,0x20>;
using ProvisioningService = BaseGattService<ProvisioningServiceUUID, SerialNumberCharacteristic, WiFiCredentialsCharacteristic, CertificateCharacteristic>;




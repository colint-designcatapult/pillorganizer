# ADR-014 Use ESP-IDF Unified WiFi Provisioning System

**Status:** Accepted

**Date:** 2026-03-03

**Authors:** Colin Tran, Brendan Heiononen

## Context and Problem Statement
Pill Organizer devices must connect to the user's WiFi network to reach AWS IoT Core.
Previously, custom BLE (Bluetooth Low Energy) provisioning logic was implemented to deliver WiFi credentials to the device.
This custom implementation was tightly coupled, difficult to maintain, and created unnecessary complexity on both the firmware and mobile app sides.
We need a standard, reliable way to deliver WiFi credentials and exchange device metadata (serial number, provisioning status) during the initial setup experience.

## Decision
We will migrate to the **ESP-IDF Unified Provisioning System**, which provides:
- **WiFi credential delivery** via BLE during device setup without custom protocol implementation
- **Vendor-neutral provisioning framework** (framework/tools) that works across Espressif devices
- **Streamlined mobile app integration** via the ESP BLE Provisioning mobile apps (or custom UI leveraging the standard protocol)
- **Separation of concerns**: BLE is now exclusively for provisioning, while AWS IoT Core MQTT handles all subsequent communication

Device provisioning flow:
1. Device boots in provisioning mode, advertises BLE service
2. Mobile app discovers device via BLE
3. Mobile app sends WiFi SSID/password via BLE using unified protocol
4. Device stores credentials, connects to WiFi
5. Device transitions to AWS IoT Fleet Provisioning for certificate enrollment
6. Device switches to MQTT for cloud communication

We rejected continuing with custom BLE provisioning because reimplementing and maintaining a custom protocol creates ongoing technical debt and increases validation complexity.

## Consequences
**Positive:**
* **Reduced firmware complexity**: Delegates credential exchange to a battle-tested, standard framework maintained by Espressif.
* **Improved mobile app UX**: Can leverage existing ESP provisioning mobile apps or standard protocol documentation for custom implementations.
* **Separation of concerns**: BLE is only used for initial provisioning; all operational communication uses AWS IoT Core, improving performance and security.
* **Easier maintenance**: If provisioning protocol needs updates, we inherit improvements from Espressif rather than maintaining custom code.
* **Industry standard**: Aligns with Espressif ecosystem best practices, easing onboarding of new team members.
* **Reduced validation burden**: Less custom code to validate for security and reliability.

**Negative:**
* **Firmware size and memory trade-off**: Unified provisioning adds some firmware size (though acceptable for ESP32).
* **Dependency on Espressif's framework**: Changes to the unified provisioning API could require firmware updates..
# ADR-010 Use ESP-AWS-IoT Library for Device-to-Cloud Communication

**Status:** Proposed

**Date:** 2026-03-02

**Authors:** Colin Tran

## Context and Problem Statement
We need a reliable, secure device-to-cloud communication solution for the ESP32 microcontroller to send telemetry data and handle Over-The-Air (OTA) updates.
The solution must support AWS IoT Core, which was chosen in ADR-001.
The device must securely authenticate using X.509 certificates.
We need to implement device provisioning without requiring pre-provisioned certificates during manufacturing.
We are a small team with limited resources for custom protocol implementation and validation.

## Decision
We will use the **ESP-AWS-IoT library** from Espressif, which provides:
- **coreMQTT** for MQTT protocol implementation with full TLS support
- **AWS IoT Fleet Provisioning** for claim-based device provisioning (Just-In-Time Registration)
- **Embedded X.509 certificate management** for mutual TLS authentication
- Built-in support for IoT Core features (Device Shadow, Jobs, Device Defender)

Device provisioning will follow the **claim-based workflow**: devices are pre-loaded with a temporary claim certificate, request a unique device certificate from AWS during first-boot provisioning, then use the device-specific certificate for all subsequent communication.

We rejected custom MQTT implementation because validation and security review of a custom protocol would exceed our team capacity and introduce unvalidated security risks.

## Consequences
**Positive:**
* Pre-validated and battle-tested by AWS and Espressif for IoT use cases.
* Eliminates need to implement MQTT protocol ourselves, reducing validation burden.
* Fleet Provisioning enables device onboarding at scale without pre-loading individual certificates.
* Integrated Device Shadow and Jobs support for robust OTA updates and device management.
* Embedded certificate management simplifies secure credential storage and TLS handshakes.
* Strong alignment with AWS IoT best practices and regulatory compliance requirements.
* Supports exponential backoff and connection resilience patterns out-of-the-box.

**Negative:**
* Tight coupling to AWS IoT ecosystem (vendor lock-in). Migrating to alternative MQTT brokers would require significant refactoring.
* Library size and memory footprint (though acceptable for ESP32).
* Requires AWS IoT Core to be configured correctly; misconfiguration could block device provisioning.
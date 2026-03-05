# End-to-End Device Provisioning Flow

This document outlines the provisioning workflow implemented. 
The process involves authenticating with a control plane API to obtain temporary claim credentials, and then using AWS IoT Fleet Provisioning to generate permanent device credentials and register the device.

## Workflow Overview

1.  **API Authentication**: Device requests claim credentials using a JWT.
2.  **MQTT Connection**: Device connects to AWS IoT using claim credentials.
3.  **Key Generation**: Device requests new permanent keys (Certificate & Private Key).
4.  **Thing Registration**: Device registers itself using a Provisioning Template, passing tenant and claim context.

## Detailed Steps

### 1. Obtain Claim Token (HTTP)

The device (via the mobile app/BLE) first contacts the Control Plane API to exchange a JWT token for a `claimId` (or `claimToken`), `deviceId`, and tenant information.

*   **URL**: `POST https://control-plane.app.healthesolutions.ca/device/claim`
*   **Headers**:
    *   `Authorization`: `Bearer {JWT_TOKEN}`
*   **Body** (Optional `deviceId` if assigning to existing):
    ```json
    {
      "serialNumber": "{SerialNumber}"
    }
    ```
*   **Response**:
    ```json
    {
      "claimId": "3AG2zI4gNE4u57Sfpyj56dHBjOq",
      "tenantId": "public",
      "tenantApiBase": "https://tenant.app.healthesolutions.ca",
      "deviceId": "3AH3xP9wMQ5v68Tgqzj67eICKPr"
    }
    ```
*   **Action**: The mobile app passes the `claimId`, `tenantId`, and `deviceId` to the device via Bluetooth LE.

### 1.5 Obtain Claim Credentials (HTTP)

The device, after connecting to Wi-Fi, uses the `claimId` and `claimToken` to request temporary AWS IoT Provisioning Claim Credentials.

*   **URL**: `POST https://control-plane.app.healthesolutions.ca/device/claim_cert`
*   **Body**:
    ```json
    {
      "serialNumber": "{SerialNumber}",
      "claimId": "3AG2zI4gNE4u57Sfpyj56dHBjOq",
      "claimToken": "{claimToken}"
    }
    ```
*   **Response**:
    ```json
    {
      "certificatePem": "-----BEGIN CERTIFICATE-----...",
      "privateKey": "-----BEGIN RSA PRIVATE KEY-----...",
      "expiration": "2026-02-27T15:12:26Z"
    }
    ```
*   **Action**: The device saves `certificatePem` and `privateKey` to local files (e.g., `claim.pem.crt`, `claim.private.key`).

### 2. Connect to AWS IoT (MQTT)

Using the credentials obtained in Step 1, the device establishes a secure MQTT connection to the AWS IoT Core endpoint.

*   **Endpoint**: `mqtt.app.healthesolutions.ca`
*   **Port**: 8883 (MQTTS)
*   **Auth**: Mutual TLS using the Claim Certificate and Private Key.
*   **Root CA**: The connection requires the Amazon Root CA 1 certificate (e.g., `root.ca.pem`).
*   **Client ID**: Must be set to the device `{SerialNumber}`.

### 3. Generate Permanent Credentials (Fleet Provisioning)

Once connected, the device initiates the `CreateKeysAndCertificate` workflow to generate a unique identity.

*   **Topic**: `$aws/certificates/create/json`
*   **Action**: Publish empty JSON payload.
*   **Response**: AWS IoT responds on `$aws/certificates/create/json/accepted` with:
    *   `certificateId`
    *   `certificatePem` (Permanent Certificate)
    *   `privateKey` (Permanent Private Key)
    *   `certificateOwnershipToken` (Used in Step 4)
*   **Local Action**: The device saves the permanent certificate and private key to secure storage (simulated by writing to `permanent.pem.crt` and `permanent.private.key`).

### 4. Register Thing (Fleet Provisioning)

The device finalizes provisioning by registering the "Thing" in the AWS IoT Registry. This step triggers the server-side Provisioning Hook (Lambda).

*   **Topic**: `$aws/provisioning-templates/TenantDeviceProvisioningTemplate/provision/json`
*   **Payload**:
    ```json
    {
      "certificateOwnershipToken": "{token_from_step_3}",
      "parameters": {
        "SerialNumber": "{SerialNumber}",
        "TenantId": "{tenantId_from_step_1}",
        "DeviceId": "{deviceId_from_step_1}",
        "ClaimId": "{claimId_from_step_1}",
        "ClaimToken": "{claimToken_from_step_1}"
      }
    }
    ```
*   **Server-Side Logic**: The Provisioning Template invokes a Lambda hook which validates the `ClaimToken` and `TenantId` before allowing the registration.
*   **Result**:
    *   A new Thing is created in AWS IoT.
    *   The permanent certificate is attached to the Thing.
    *   The Thing is attached to the appropriate policy.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Device
    participant API as Control Plane API
    participant IoT as AWS IoT Core
    participant Lambda as Provisioning Hook

    Note over Device: Has SerialNumber & JWT

    Device->>API: POST /device/claim {SerialNumber} (Auth: Bearer JWT)
    API-->>Device: 200 OK {ClaimId, TenantId, ApiBase, DeviceId}

    Note over Device: Device Connects to WiFi

    Device->>API: POST /device/claim_cert {SerialNumber, ClaimId, ClaimToken}
    API-->>Device: 200 OK {ClaimCert, ClaimKey, Expiration}

    Device->>Device: Save Claim Certs

    Device->>IoT: MQTT Connect (mTLS with Claim Cert)
    IoT-->>Device: Connected

    Device->>IoT: Pub CreateKeysAndCertificate
    IoT-->>Device: Accepted {PermCert, PermKey, OwnerToken}

    Device->>Device: Save Permanent Certs

    Device->>IoT: Pub RegisterThing (Token, Params: {TenantId, ClaimToken...})
    IoT->>Lambda: Invoke Pre-Provisioning Hook
    Lambda->>Lambda: Validate ClaimToken & Tenant
    Lambda-->>IoT: Allow & Return Policy
    IoT-->>Device: Accepted {ThingName, ...}

    Note over Device: Provisioning Complete
```
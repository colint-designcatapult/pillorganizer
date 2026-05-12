import sys
import json
import urllib.request
import os
import csv
import time
from concurrent.futures import Future

from awscrt import io, mqtt
from awsiot import mqtt_connection_builder
from awsiot.iotidentity import IotIdentityClient, CreateKeysAndCertificateRequest, RegisterThingRequest

# Cryptography imports for .p12 conversion
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.hazmat.primitives import serialization
from cryptography.x509 import load_pem_x509_certificate

# Assuming this is your custom helper
from cognito_helper import get_jwt_token

# --- Configuration ---
ENDPOINT = "mqtt.app.healthesolutions.ca"
TEMPLATE_NAME = "TenantDeviceProvisioningTemplate"
ROOT_CA = "root.ca.pem"

COGNITO_CLIENT_ID = os.getenv("COGNITO_CLIENT_ID", "2ofl5qi7qfqopfph6dqff0dl61")
COGNITO_USERNAME = os.getenv("COGNITO_USERNAME", "test-account-1@healthesolutions.ca")
COGNITO_PASSWORD = os.getenv("COGNITO_PASSWORD", "HealthETest1!")

OUT_DIR = "provisioned_devices"
CSV_OUTPUT = "devices.csv"
P12_PASSWORD = b"changeit" # JMeter requires a password for Keystores

NUM_DEVICES = 2000

def provision_device(serial_number, jwt_token, client_bootstrap):
    print(f"\n--- Provisioning {serial_number} ---")
    device_dir = os.path.join(OUT_DIR, serial_number)
    os.makedirs(device_dir, exist_ok=True)

    claim_cert_path = os.path.join(device_dir, "claim.pem.crt")
    claim_key_path = os.path.join(device_dir, "claim.private.key")
    p12_path = os.path.join(device_dir, f"{serial_number}.p12")

    # --- Fetch Claim Token from API ---
    api_url = "https://control-plane.app.healthesolutions.ca/device/claim"
    req_data = json.dumps({"serialNumber": serial_number}).encode('utf-8')
    req = urllib.request.Request(api_url, data=req_data, method='POST')
    req.add_header("Authorization", f"Bearer {jwt_token}")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as response:
            if response.status != 200:
                raise Exception(f"API returned status {response.status}")
            data = json.loads(response.read().decode())
            claim_id = data['claimId']
            claim_token = data['claimToken']
    except Exception as e:
        print(f"❌ Failed to fetch claim token for {serial_number}: {e}")
        return None

    # --- Fetch Claim Credentials from API using Token ---
    cert_api_url = "https://control-plane.app.healthesolutions.ca/device/claim_cert"
    cert_req_data = json.dumps({"serialNumber": serial_number, "claimId": claim_id, "claimToken": claim_token}).encode('utf-8')
    cert_req = urllib.request.Request(cert_api_url, data=cert_req_data, method='POST')
    cert_req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(cert_req) as response:
            if response.status != 200:
                raise Exception(f"API returned status {response.status}")
            cert_data = json.loads(response.read().decode())
            with open(claim_cert_path, 'w') as f:
                f.write(cert_data['certificatePem'])
            with open(claim_key_path, 'w') as f:
                f.write(cert_data['privateKey'])
    except Exception as e:
        print(f"❌ Failed to fetch claim credentials for {serial_number}: {e}")
        return None

    # --- Connect to MQTT ---
    mqtt_connection = mqtt_connection_builder.mtls_from_path(
        endpoint=ENDPOINT,
        cert_filepath=claim_cert_path,
        pri_key_filepath=claim_key_path,
        ca_filepath=ROOT_CA,
        client_bootstrap=client_bootstrap,
        client_id=serial_number,
        clean_session=True,
        keep_alive_secs=30
    )

    mqtt_connection.connect().result()
    identity_client = IotIdentityClient(mqtt_connection)

    # --- Futures and Callbacks for this specific device ---
    keys_future = Future()
    register_future = Future()

    def on_keys_accepted(response):
        keys_future.set_result(response)

    def on_keys_rejected(rejected):
        keys_future.set_exception(Exception(rejected.error_message))

    def on_register_accepted(response):
        register_future.set_result(response.thing_name)

    def on_register_rejected(rejected):
        register_future.set_exception(Exception(rejected.error_message))

    # Phase 1: Permanent Keys
    identity_client.subscribe_to_create_keys_and_certificate_accepted(
        request=CreateKeysAndCertificateRequest(), qos=mqtt.QoS.AT_LEAST_ONCE, callback=on_keys_accepted)
    identity_client.subscribe_to_create_keys_and_certificate_rejected(
        request=CreateKeysAndCertificateRequest(), qos=mqtt.QoS.AT_LEAST_ONCE, callback=on_keys_rejected)

    identity_client.publish_create_keys_and_certificate(
        request=CreateKeysAndCertificateRequest(), qos=mqtt.QoS.AT_LEAST_ONCE)

    keys_response = keys_future.result()

    # Phase 2: Register Thing
    identity_client.subscribe_to_register_thing_accepted(
        request=RegisterThingRequest(template_name=TEMPLATE_NAME), qos=mqtt.QoS.AT_LEAST_ONCE, callback=on_register_accepted)
    identity_client.subscribe_to_register_thing_rejected(
        request=RegisterThingRequest(template_name=TEMPLATE_NAME), qos=mqtt.QoS.AT_LEAST_ONCE, callback=on_register_rejected)

    register_request = RegisterThingRequest(
        template_name=TEMPLATE_NAME,
        certificate_ownership_token=keys_response.certificate_ownership_token,
        parameters={"SerialNumber": serial_number, "ClaimId": claim_id, "ClaimToken": claim_token}
    )

    identity_client.publish_register_thing(
        request=register_request, qos=mqtt.QoS.AT_LEAST_ONCE)

    thing_name = register_future.result()

    # Clean up connection
    mqtt_connection.disconnect().result()

    # --- Convert PEM to P12 for JMeter ---
    cert_bytes = keys_response.certificate_pem.encode('utf-8')
    key_bytes = keys_response.private_key.encode('utf-8')

    cert_obj = load_pem_x509_certificate(cert_bytes)
    key_obj = serialization.load_pem_private_key(key_bytes, password=None)

    p12_bytes = pkcs12.serialize_key_and_certificates(
        name=serial_number.encode('utf-8'), # The JMeter alias will match the serial number
        key=key_obj,
        cert=cert_obj,
        cas=None,
        encryption_algorithm=serialization.BestAvailableEncryption(P12_PASSWORD)
    )

    with open(p12_path, "wb") as f:
        f.write(p12_bytes)

    print(f"✅ Success: {thing_name} provisioned. Saved to {p12_path}")
    return p12_path, thing_name


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    # Initialize AWS CRT just once for the whole loop
    event_loop_group = io.EventLoopGroup(1)
    host_resolver = io.DefaultHostResolver(event_loop_group)
    client_bootstrap = io.ClientBootstrap(event_loop_group, host_resolver)

    print("Authenticating with Cognito...")
    jwt_token = get_jwt_token(COGNITO_CLIENT_ID, COGNITO_USERNAME, COGNITO_PASSWORD)
    if not jwt_token:
        print("❌ Failed to obtain JWT token. Exiting.")
        sys.exit(1)

    # Open CSV for writing
    with open(CSV_OUTPUT, mode='w', newline='') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow(["SerialNumber", "P12FilePath", "ThingName"]) # Headers

        # Loop 2000 times
        for i in range(1, NUM_DEVICES + 1):
            serial_number = f"BENCHMARK{i:04d}"

            result = provision_device(serial_number, jwt_token, client_bootstrap)

            if result:
                p12_path, thing_name = result
                writer.writerow([serial_number, p12_path, thing_name])
                # Flush to disk immediately so you don't lose data if the script crashes on device 1,500
                csv_file.flush()

            # Optional: A tiny sleep to prevent hammering your API rate limits too aggressively
            time.sleep(0.1)

    print(f"\n🎉 Bulk Provisioning Complete! Check {CSV_OUTPUT}.")

if __name__ == '__main__':
    main()

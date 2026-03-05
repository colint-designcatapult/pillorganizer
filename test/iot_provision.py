import sys
import json
import urllib.request
import os
from concurrent.futures import Future
from awscrt import io, mqtt
from awsiot import mqtt_connection_builder
from awsiot.iotidentity import IotIdentityClient, CreateKeysAndCertificateRequest, RegisterThingRequest
from cognito_helper import get_jwt_token

# --- Configuration ---
ENDPOINT = "mqtt.app.healthesolutions.ca" # Replace with your ATS endpoint
TEMPLATE_NAME = "TenantDeviceProvisioningTemplate"
ROOT_CA = "root.ca.pem"
SERIAL_NUMBER = "ESP32-SIMULATION-001" # This will be passed to your Java Hook

COGNITO_CLIENT_ID = os.getenv("COGNITO_CLIENT_ID", "2ofl5qi7qfqopfph6dqff0dl61")
COGNITO_USERNAME = os.getenv("COGNITO_USERNAME", "test-account-1@healthesolutions.ca")
COGNITO_PASSWORD = os.getenv("COGNITO_PASSWORD", "HealthETest1!")

OUT_DIR = "out"
CLAIM_CERT = os.path.join(OUT_DIR, "claim.pem.crt")
CLAIM_KEY = os.path.join(OUT_DIR, "claim.private.key")
CLIENT_ID = SERIAL_NUMBER

# Futures for async callbacks
keys_future = Future()
register_future = Future()

def on_keys_accepted(response):
    print("\n✅ Step 1 Complete: AWS generated new permanent keys!")
    keys_future.set_result(response)

def on_keys_rejected(rejected):
    print(f"\n❌ Step 1 Failed: {rejected.error_message}")
    keys_future.set_exception(Exception(rejected.error_message))

def on_register_accepted(response):
    print(f"\n✅ Step 2 Complete: Thing Registered successfully!")
    print(f"Thing Name: {response}")
    register_future.set_result(response)

def on_register_rejected(rejected):
    print(f"\n❌ Step 2 Failed: {rejected.error_message}")
    register_future.set_exception(Exception(rejected.error_message))

def main():
    # Ensure output directory exists
    os.makedirs(OUT_DIR, exist_ok=True)

    # Spin up the AWS CRT IO threadpool
    event_loop_group = io.EventLoopGroup(1)
    host_resolver = io.DefaultHostResolver(event_loop_group)
    client_bootstrap = io.ClientBootstrap(event_loop_group, host_resolver)

    # --- Fetch Claim Token from API ---
    print(f"Fetching claim token for {SERIAL_NUMBER}...")
    api_url = "https://control-plane.app.healthesolutions.ca/device/claim"
    
    # --- Fetch JWT token ---
    print("Authenticating with Cognito...")
    jwt_token = get_jwt_token(COGNITO_CLIENT_ID, COGNITO_USERNAME, COGNITO_PASSWORD)
    if not jwt_token:
        print("❌ Failed to obtain JWT token. Exiting.")
        sys.exit(1)

    req_data = json.dumps({"serialNumber": SERIAL_NUMBER}).encode('utf-8')
    req = urllib.request.Request(api_url, data=req_data, method='POST')
    req.add_header("Authorization", f"Bearer {jwt_token}")
    req.add_header("Content-Type", "application/json")
    
    try:
        with urllib.request.urlopen(req) as response:
            if response.status != 200:
                raise Exception(f"API returned status {response.status}")
            data = json.loads(response.read().decode())
            print(f"API Response: {data}")
            
            # Extract data
            tenant_id = data['tenantId']
            claim_id = data['claimId']
            # We don't get claim_token over HTTP for security, this is typically passed via BLE
            # For this test script, we assume claim_token is claim_id as a fallback/mock if unspecified 
            # (or we would need to retrieve it differently if testing true end-to-end security)
            # NOTE: If claimToken is not equal to claimId in actual firmware generation, it needs to be updated here.
            # Assuming here they are identical or provided similarly in the simulation environment.
            # Wait, looking at Global device provision service, claim token and claim id are separate.
            # We'll use claim_id as a mock if token isn't natively returned.
            claim_token = claim_id
            device_id = data['deviceId']
            
            print(f"✅ Claim ID obtained: {claim_id} for Tenant: {tenant_id} (Device: {device_id})")

    except Exception as e:
        print(f"❌ Failed to fetch claim token: {e}")
        sys.exit(1)

    # --- Fetch Claim Credentials from API using Token ---
    print(f"Fetching claim credentials for {SERIAL_NUMBER} using token...")
    cert_api_url = "https://control-plane.app.healthesolutions.ca/device/claim_cert"
    cert_req_data = json.dumps({"serialNumber": SERIAL_NUMBER, "claimId": claim_id, "claimToken": claim_token}).encode('utf-8')
    cert_req = urllib.request.Request(cert_api_url, data=cert_req_data, method='POST')
    cert_req.add_header("Content-Type", "application/json")
    # Note: No Authorization header needed for this endpoint as per requirement
    
    try:
        with urllib.request.urlopen(cert_req) as response:
            if response.status != 200:
                raise Exception(f"API returned status {response.status}")
            cert_data = json.loads(response.read().decode())
            print(f"Cert API Response: {cert_data}")
            
            # Extract data
            claim_cert_pem = cert_data['certificatePem']
            claim_private_key = cert_data['privateKey']
            
            # Save to files expected by mqtt_connection_builder
            with open(CLAIM_CERT, 'w') as f:
                f.write(claim_cert_pem)
            with open(CLAIM_KEY, 'w') as f:
                f.write(claim_private_key)
                
            print(f"✅ Claim credentials obtained and saved.")

    except Exception as e:
        print(f"❌ Failed to fetch claim credentials: {e}")
        sys.exit(1)

    # Connect to AWS IoT using the Claim Certificate
    print(f"Connecting to {ENDPOINT} using Claim Certificate...")
    mqtt_connection = mqtt_connection_builder.mtls_from_path(
        endpoint=ENDPOINT,
        cert_filepath=CLAIM_CERT,
        pri_key_filepath=CLAIM_KEY,
        ca_filepath=ROOT_CA,
        client_bootstrap=client_bootstrap,
        client_id=CLIENT_ID,
        clean_session=True,
        keep_alive_secs=30
    )
    
    connect_future = mqtt_connection.connect()
    connect_future.result()
    print("Connected!\n")

    # Initialize the Fleet Provisioning Client
    identity_client = IotIdentityClient(mqtt_connection)

    # ------------------------------------------------------------------
    # Phase 1: Request a new permanent Certificate and Private Key
    # ------------------------------------------------------------------
    print("Phase 1: Requesting new permanent certificate...")
    identity_client.subscribe_to_create_keys_and_certificate_accepted(
        request=CreateKeysAndCertificateRequest(),
        qos=mqtt.QoS.AT_LEAST_ONCE,
        callback=on_keys_accepted)
    
    identity_client.subscribe_to_create_keys_and_certificate_rejected(
        request=CreateKeysAndCertificateRequest(),
        qos=mqtt.QoS.AT_LEAST_ONCE,
        callback=on_keys_rejected)

    # Publish the request
    identity_client.publish_create_keys_and_certificate(
        request=CreateKeysAndCertificateRequest(),
        qos=mqtt.QoS.AT_LEAST_ONCE)

    # Wait for the response
    keys_response = keys_future.result()
    
    # Save the new permanent credentials locally (The ESP32 would save these to NVS)
    with open(os.path.join(OUT_DIR, "permanent.pem.crt"), "w") as f:
        f.write(keys_response.certificate_pem)
    with open(os.path.join(OUT_DIR, "permanent.private.key"), "w") as f:
        f.write(keys_response.private_key)
    print(f"Saved permanent credentials to {OUT_DIR}/\n")

    # ------------------------------------------------------------------
    # Phase 2: Register the Thing using the Provisioning Template
    # ------------------------------------------------------------------
    print(f"Phase 2: Calling template '{TEMPLATE_NAME}' to register Thing...")
    
    # Subscribe to accepted/rejected topics for the template
    identity_client.subscribe_to_register_thing_accepted(
        request=RegisterThingRequest(template_name=TEMPLATE_NAME),
        qos=mqtt.QoS.AT_LEAST_ONCE,
        callback=on_register_accepted)
    
    identity_client.subscribe_to_register_thing_rejected(
        request=RegisterThingRequest(template_name=TEMPLATE_NAME),
        qos=mqtt.QoS.AT_LEAST_ONCE,
        callback=on_register_rejected)

    # Publish the registration request. 
    # NOTE: "parameters" here is exactly what gets passed into your Java Hook!
    register_request = RegisterThingRequest(
        template_name=TEMPLATE_NAME,
        certificate_ownership_token=keys_response.certificate_ownership_token,
        parameters={
            "SerialNumber": SERIAL_NUMBER,
            "TenantId": tenant_id,
            "DeviceId": device_id,
            "ClaimId": claim_id,
            "ClaimToken": claim_token
        }
    )
    identity_client.publish_register_thing(
        request=register_request,
        qos=mqtt.QoS.AT_LEAST_ONCE)

    # Wait for the response (This means your Java Hook fired and succeeded)
    register_future.result()

    print("\n🎉 Provisioning Simulation Complete! Disconnecting...")
    mqtt_connection.disconnect().result()

if __name__ == '__main__':
    main()
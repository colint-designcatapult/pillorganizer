#!/usr/bin/env python3
"""
IoT load test: sends a QoS 1 MQTT state message for each device in devices.csv
using a thread pool of 25 workers and mosquitto_pub with per-device X.509 certs.

Prerequisite: run extract_certs.py first to populate CertFilePath/KeyFilePath
columns in devices.csv from the per-device .p12 bundles.
"""

import csv
import json
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────────────
MOSQUITTO_PUB = r"C:\Program Files\Mosquitto\mosquitto_pub.exe"
BROKER_HOST   = "mqtt.app.healthesolutions.ca"
BROKER_PORT   = 8883
THREAD_POOL   = 25
CSV_FILE      = Path(__file__).parent / "devices.csv"
CA_FILE       = Path(__file__).parent / "root.ca.pem"

PAYLOAD = {
    "timestamp": 1778535541681,
    "battery": {"usb": 1, "pg": 1, "con": 1, "chg": 0, "pct": 100},
    "reload": {"needed": False},
    "doors": 0,
    "epoch_week": 1778472000,
    "error_flags": 0,
    "fw_version": "0.0.0",
    "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2",
    "timezoneIana": "America/New_York",
    "timezonePosix": "EST5EDT,M3.2.0,M11.1.0",
    "bins": [
        {"id": 0,  "status": "DISABLED", "scheduled_time": 1778529600, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 1,  "status": "DISABLED", "scheduled_time": 1778500800, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 2,  "status": "PENDING",  "scheduled_time": 1778616000, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 3,  "status": "TAKEN",    "scheduled_time": 1778587200, "event_time": 1778530180316, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 4,  "status": "PENDING",  "scheduled_time": 1778702400, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 5,  "status": "PENDING",  "scheduled_time": 1778673600, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 6,  "status": "PENDING",  "scheduled_time": 1778788800, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 7,  "status": "PENDING",  "scheduled_time": 1778760000, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 8,  "status": "PENDING",  "scheduled_time": 1778875200, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 9,  "status": "PENDING",  "scheduled_time": 1778846400, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 10, "status": "PENDING",  "scheduled_time": 1778961600, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 11, "status": "PENDING",  "scheduled_time": 1778932800, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 12, "status": "PENDING",  "scheduled_time": 1779048000, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
        {"id": 13, "status": "PENDING",  "scheduled_time": 1779019200, "schedule_id": "bcf1abba-53c0-41ef-a85a-6f5f341bdfb2"},
    ],
}

PAYLOAD_JSON = json.dumps(PAYLOAD, separators=(",", ":"))


def publish(thing_name: str, cert_file: Path, key_file: Path) -> tuple[str, bool, str]:
    """Run mosquitto_pub for one device; returns (thing_name, success, detail)."""
    topic = f"healthe/things/{thing_name}/state"

    cmd = [
        MOSQUITTO_PUB,
        "-h", BROKER_HOST,
        "-p", str(BROKER_PORT),
        "--cafile", str(CA_FILE),
        "--cert",   str(cert_file),
        "--key",    str(key_file),
        "-i", thing_name,
        "-t", topic,
        "-q", "1",
        "-m", PAYLOAD_JSON,
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            return thing_name, True, "OK"
        detail = (result.stderr or result.stdout).strip().splitlines()[0] if (result.stderr or result.stdout) else f"exit {result.returncode}"
        return thing_name, False, detail
    except subprocess.TimeoutExpired:
        return thing_name, False, "timeout"
    except Exception as exc:
        return thing_name, False, str(exc)


def load_devices() -> list[tuple[str, Path, Path]]:
    """Returns list of (thing_name, cert_path, key_path) from devices.csv."""
    base    = Path(__file__).parent
    devices = []
    with open(CSV_FILE, newline="") as f:
        for row in csv.DictReader(f):
            if not row.get("CertFilePath") or not row.get("KeyFilePath"):
                print(f"SKIP {row['SerialNumber']}: missing CertFilePath/KeyFilePath — run extract_certs.py first")
                continue
            devices.append((
                row["ThingName"].strip(),
                base / row["CertFilePath"].strip(),
                base / row["KeyFilePath"].strip(),
            ))
    return devices


def main():
    devices = load_devices()
    if not devices:
        print("No devices to test. Run extract_certs.py first.")
        sys.exit(1)

    total = len(devices)
    print(f"Loaded {total} devices — starting load test with {THREAD_POOL} threads\n")

    ok_count   = 0
    fail_count = 0
    start      = time.monotonic()

    with ThreadPoolExecutor(max_workers=THREAD_POOL) as pool:
        futures = {pool.submit(publish, thing, cert, key): thing
                   for thing, cert, key in devices}

        for i, future in enumerate(as_completed(futures), 1):
            thing_name, success, detail = future.result()
            if success:
                ok_count += 1
                status = "OK"
            else:
                fail_count += 1
                status = f"FAIL  {detail}"

            elapsed = time.monotonic() - start
            rate    = i / elapsed if elapsed > 0 else 0
            print(f"[{i:>4}/{total}] {status:<40} {thing_name}  ({rate:.1f}/s)", flush=True)

    elapsed = time.monotonic() - start
    print(f"\n{'─'*60}")
    print(f"Done in {elapsed:.1f}s  |  {ok_count} succeeded  |  {fail_count} failed")
    sys.exit(0 if fail_count == 0 else 1)


if __name__ == "__main__":
    main()

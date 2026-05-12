#!/usr/bin/env python3
"""
One-time conversion: reads devices.csv, extracts the permanent PEM cert + key
from each device's .p12 bundle, writes them alongside the .p12, then rewrites
devices.csv with two new columns: CertFilePath and KeyFilePath.

Run this once before load_test.py.
"""

import csv
import sys
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization import pkcs12

CSV_FILE     = Path(__file__).parent / "devices.csv"
P12_PASSWORD = b"changeit"


def extract_p12(p12_path: Path) -> tuple[Path, Path]:
    """Extract cert + key PEM files next to the .p12; returns (cert_path, key_path)."""
    with open(p12_path, "rb") as f:
        private_key, certificate, _ = pkcs12.load_key_and_certificates(f.read(), P12_PASSWORD)

    cert_pem = certificate.public_bytes(serialization.Encoding.PEM)
    key_pem  = private_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption(),
    )

    cert_out = p12_path.with_suffix(".pem.crt")
    key_out  = p12_path.with_suffix(".private.key")
    cert_out.write_bytes(cert_pem)
    key_out.write_bytes(key_pem)
    return cert_out, key_out


def main():
    base = Path(__file__).parent

    with open(CSV_FILE, newline="") as f:
        rows = list(csv.DictReader(f))

    if not rows:
        print("devices.csv is empty — nothing to do.")
        sys.exit(1)

    if "CertFilePath" in rows[0] and "KeyFilePath" in rows[0]:
        print("devices.csv already has CertFilePath/KeyFilePath columns.")
        print("Delete those columns and re-run if you want to re-extract.")
        sys.exit(0)

    total   = len(rows)
    ok      = 0
    skipped = 0

    for i, row in enumerate(rows, 1):
        serial   = row["SerialNumber"]
        p12_path = base / row["P12FilePath"]

        try:
            cert_path, key_path = extract_p12(p12_path)
            row["CertFilePath"] = str(cert_path.relative_to(base))
            row["KeyFilePath"]  = str(key_path.relative_to(base))
            ok += 1
        except Exception as exc:
            print(f"  [{i:>4}/{total}] SKIP {serial}: {exc}")
            row["CertFilePath"] = ""
            row["KeyFilePath"]  = ""
            skipped += 1

        if i % 100 == 0 or i == total:
            print(f"  [{i:>4}/{total}] extracted...", flush=True)

    fieldnames = ["SerialNumber", "P12FilePath", "CertFilePath", "KeyFilePath", "ThingName"]
    with open(CSV_FILE, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nDone — {ok} extracted, {skipped} skipped.")
    print(f"devices.csv updated with CertFilePath and KeyFilePath columns.")


if __name__ == "__main__":
    main()

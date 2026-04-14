#!/usr/bin/env bash
# push-ota.sh — Upload firmware and create an AWS IoT Core OTA job
#
# Usage:
#   ./scripts/push-ota.sh --version <version> --binary <path> --target <arn> \
#                         [--bucket <name>] [--presign-role-arn <arn>] [--region <region>]
#
# Arguments:
#   --version          Firmware version string matching PROJECT_VER in CMakeLists.txt (e.g. "1.2.0")
#   --binary           Path to the compiled firmware .bin file
#   --target           ARN of the IoT thing or thing group to receive the update
#                      (e.g. arn:aws:iot:ca-central-1:123456789012:thing/my-device
#                       or   arn:aws:iot:ca-central-1:123456789012:thinggroup/cabinet-fleet)
#   --bucket           Firmware S3 bucket name. Defaults to $FIRMWARE_BUCKET env var.
#   --presign-role-arn IAM role ARN that IoT Jobs uses to presign S3 URLs per device.
#                      Defaults to $PRESIGN_ROLE_ARN env var.
#                      (Output "PresignRoleArn" from the FirmwareStack CDK deployment)
#   --region           AWS region. Defaults to the AWS CLI configured default.
#
# How presigning works:
#   The job document contains a ${aws:iot:s3-presigned-url:<url>} placeholder.
#   AWS IoT Jobs resolves this to a fresh presigned URL for each device at the
#   moment it fetches the job document — so URLs never expire, and devices
#   provisioned after job creation still receive a valid download link.
#
# Prerequisites:
#   - AWS CLI v2 with credentials that have iot:CreateJob, s3:PutObject, and
#     iam:PassRole (for the presign role) access
#   - The FirmwareStack CDK stack must already be deployed

set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
VERSION=""
BINARY=""
TARGET=""
BUCKET="${FIRMWARE_BUCKET:-}"
PRESIGN_ROLE_ARN="${PRESIGN_ROLE_ARN:-}"
REGION="${AWS_DEFAULT_REGION:-${AWS_REGION:-}}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)          VERSION="$2";          shift 2 ;;
        --binary)           BINARY="$2";           shift 2 ;;
        --target)           TARGET="$2";           shift 2 ;;
        --bucket)           BUCKET="$2";           shift 2 ;;
        --presign-role-arn) PRESIGN_ROLE_ARN="$2"; shift 2 ;;
        --region)           REGION="$2";           shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# Fall back to CLI-configured region if not set
if [[ -z "$REGION" ]]; then
    REGION="$(aws configure get region)"
fi

if [[ -z "$VERSION" || -z "$BINARY" || -z "$TARGET" || -z "$BUCKET" || -z "$PRESIGN_ROLE_ARN" ]]; then
    echo "Usage: $0 --version <ver> --binary <path> --target <arn> [--bucket <name>] [--presign-role-arn <arn>] [--region <region>]" >&2
    echo "Set FIRMWARE_BUCKET and PRESIGN_ROLE_ARN env vars to avoid passing them each time." >&2
    exit 1
fi

if [[ ! -f "$BINARY" ]]; then
    echo "Error: binary file not found: $BINARY" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Derive names
# ---------------------------------------------------------------------------
S3_KEY="firmware/${VERSION}/firmware.bin"
JOB_ID="ota-${VERSION//\./-}-$(date +%s)"
S3_URL="https://${BUCKET}.s3.${REGION}.amazonaws.com/${S3_KEY}"

# The ${aws:iot:s3-presigned-url:<url>} placeholder is resolved by IoT Jobs
# to a fresh presigned URL each time a device fetches the job document.
# The \$ prevents bash from expanding this — it must reach IoT literally.
JOB_DOCUMENT="{\"url\":\"\${aws:iot:s3-presigned-url:${S3_URL}}\",\"version\":\"${VERSION}\",\"type\":\"ota\"}"

# ---------------------------------------------------------------------------
# Upload firmware binary
# ---------------------------------------------------------------------------
echo "Uploading ${BINARY} to s3://${BUCKET}/${S3_KEY}"
aws s3 cp "$BINARY" "s3://${BUCKET}/${S3_KEY}" --region "$REGION"
echo "Upload complete."

# ---------------------------------------------------------------------------
# Create the IoT job
# ---------------------------------------------------------------------------
echo "Creating IoT job: ${JOB_ID}"
aws iot create-job \
    --region "$REGION" \
    --job-id "$JOB_ID" \
    --targets "$TARGET" \
    --document "$JOB_DOCUMENT" \
    --description "Firmware OTA update to version ${VERSION}" \
    --presigned-url-config "roleArn=${PRESIGN_ROLE_ARN},expiresInSec=3600" \
    --job-executions-rollout-config '{
        "exponentialRate": {
            "baseRatePerMinute": 10,
            "incrementFactor": 1.2,
            "rateIncreaseCriteria": {
                "numberOfNotifiedThings": 1
            }
        },
        "maximumPerMinute": 100
    }' \
    --abort-config '{
        "criteriaList": [{
            "action": "CANCEL",
            "failureType": "FAILED",
            "minNumberOfExecutedThings": 10,
            "thresholdPercentage": 20
        }]
    }'

echo ""
echo "OTA job created successfully."
echo "  Job ID   : ${JOB_ID}"
echo "  Version  : ${VERSION}"
echo "  Target   : ${TARGET}"
echo "  S3 key   : s3://${BUCKET}/${S3_KEY}"
echo "  Region   : ${REGION}"

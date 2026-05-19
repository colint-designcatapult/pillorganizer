<#
.SYNOPSIS
Upload firmware and create an AWS IoT Core OTA job

.DESCRIPTION
This script uploads a compiled firmware binary to an S3 bucket and creates an AWS IoT job.

.EXAMPLE
.\push-ota.ps1 -Version "1.2.0" -Binary ".\build\firmware.bin" -Target "arn:aws:iot:ca-central-1:123456789012:thing/my-device"
#>

[CmdletBinding()]
param (
    # Firmware version string matching PROJECT_VER in CMakeLists.txt
    [Parameter(Mandatory=$true)]
    [string]$Version,

    # Path to the compiled firmware .bin file
    [Parameter(Mandatory=$true)]
    [string]$Binary,

    # ARN of the IoT thing or thing group to receive the update
    [Parameter(Mandatory=$true)]
    [string]$Target,

    # Firmware S3 bucket name. Defaults to FIRMWARE_BUCKET env var.
    [string]$Bucket = "healthe-firmware-114829892869-ca-central-1",

    # IAM role ARN that IoT Jobs uses to presign S3 URLs per device. Defaults to PRESIGN_ROLE_ARN env var.
    [string]$PresignRoleArn = "arn:aws:iam::114829892869:role/HealtheFirmwareStack-IotPresignRole34F74DF5-yo80mrJRcD49",

    # AWS region. Defaults to the AWS CLI configured default.
    [string]$Region = "ca-central-1"
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Argument & Environment parsing
# ---------------------------------------------------------------------------

# Fall back to AWS_REGION env var, then CLI-configured region if not set
if ([string]::IsNullOrWhiteSpace($Region)) {
    $Region = $env:AWS_REGION
    if ([string]::IsNullOrWhiteSpace($Region)) {
        $Region = (aws configure get region).Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($Bucket) -or [string]::IsNullOrWhiteSpace($PresignRoleArn)) {
    Write-Error "Bucket and PresignRoleArn must be provided via arguments or environment variables (FIRMWARE_BUCKET / PRESIGN_ROLE_ARN)."
    exit 1
}

if (-not (Test-Path -Path $Binary -PathType Leaf)) {
    Write-Error "Error: binary file not found: $Binary"
    exit 1
}

# ---------------------------------------------------------------------------
# Derive names
# ---------------------------------------------------------------------------
$S3Key = "firmware/${Version}/firmware.bin"
$Timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$SanitizedVersion = $Version -replace '\.', '-'
$JobId = "ota-${SanitizedVersion}-${Timestamp}"
$S3Url = "https://${Bucket}.s3.${Region}.amazonaws.com/${S3Key}"

# The ${aws:iot:s3-presigned-url:<url>} placeholder is resolved by IoT Jobs
# to a fresh presigned URL each time a device fetches the job document.
# Note: Using backticks (`) to escape quotes and the dollar sign so PowerShell 
# passes the exact literal string to the AWS CLI.
$JobDocument = "{`"url`":`"`${aws:iot:s3-presigned-url:${S3Url}}`",`"version`":`"${Version}`",`"type`":`"ota`"}"

# ---------------------------------------------------------------------------
# Upload firmware binary
# ---------------------------------------------------------------------------
Write-Host "Uploading ${Binary} to s3://${Bucket}/${S3Key}"
aws s3 cp "$Binary" "s3://${Bucket}/${S3Key}" --region "$Region"
Write-Host "Upload complete."

# ---------------------------------------------------------------------------
# Create the IoT job
# ---------------------------------------------------------------------------
Write-Host "Creating IoT job: ${JobId}"

# PowerShell strips double-quotes when passing strings to native executables (aws.exe).
# We append .Replace('"', '\"') to force backslash-escaping so AWS CLI gets valid JSON.
$JobDocument = "{`"url`":`"`${aws:iot:s3-presigned-url:${S3Url}}`",`"version`":`"${Version}`",`"type`":`"ota`"}".Replace('"', '\"')

$RolloutConfig = '{"exponentialRate":{"baseRatePerMinute":10,"incrementFactor":1.2,"rateIncreaseCriteria":{"numberOfNotifiedThings":1}},"maximumPerMinute":100}'.Replace('"', '\"')

$AbortConfig = '{"criteriaList":[{"action":"CANCEL","failureType":"FAILED","minNumberOfExecutedThings":10,"thresholdPercentage":20}]}'.Replace('"', '\"')

$PresignedUrlConfig = "roleArn=${PresignRoleArn},expiresInSec=3600"
$JobDescription = "Firmware OTA update to version ${Version}"

aws iot create-job `
    --region "$Region" `
    --job-id "$JobId" `
    --targets "$Target" `
    --document "$JobDocument" `
    --description "$JobDescription" `
    --presigned-url-config "$PresignedUrlConfig" `
    --job-executions-rollout-config "$RolloutConfig" `
    --abort-config "$AbortConfig"

Write-Host ""
Write-Host "OTA job created successfully." -ForegroundColor Green
Write-Host "  Job ID   : ${JobId}"
Write-Host "  Version  : ${Version}"
Write-Host "  Target   : ${Target}"
Write-Host "  S3 key   : s3://${Bucket}/${S3Key}"
Write-Host "  Region   : ${Region}"
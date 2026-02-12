#!/bin/bash

# Use ca-central-1 Canadian region
export AWS_DEFAULT_REGION=ca-central-1

# Variable to control whether this is local/test, etc
# Defaults to local if not set in environment variable already
: "${ENVIRONMENT_KEY:=local}"

# Build secret in RDS format
DB_SECRET_JSON=$(cat <<EOF
{
  "username": "postgres",
  "password": "root"
}
EOF
)

awslocal secretsmanager create-secret \
    --name /config/pillorganizer-backend_${ENVIRONMENT_KEY}/database \
    --description "Tenant development database credentials" \
    --secret-string "${DB_SECRET_JSON}"

# Control Plane DynamoDB Tables

DYNAMO_DEVICE_ASSOCIATION=$(cat <<EOF
{
    "TableName": "DeviceAssociation",
    "KeySchema": [
        { "AttributeName": "DeviceUniqueId", "KeyType": "HASH" }
    ],
    "AttributeDefinitions": [
        { "AttributeName": "DeviceUniqueId", "AttributeType": "S" },
        { "AttributeName": "TenantId", "AttributeType": "S" },
        { "AttributeName": "ProvisioningStatus", "AttributeType": "S" }
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "DeviceTenantIndex",
            "KeySchema": [
                { "AttributeName": "TenantId", "KeyType": "HASH" },
                { "AttributeName": "ProvisioningStatus", "KeyType": "RANGE" }
            ],
            "Projection": {
              "ProjectionType": "ALL"
            },
            "ProvisionedThroughput": {
                "ReadCapacityUnits": 5,
                "WriteCapacityUnits": 5
            }
        }
    ],
    "BillingMode": "PAY_PER_REQUEST"
}
EOF
)

awslocal dynamodb create-table --cli-input-json "${DYNAMO_DEVICE_ASSOCIATION}"

DYNAMO_DEVICE_REGISTRY=$(cat <<EOF
{
    "TableName": "DeviceRegistry",
    "KeySchema": [
        { "AttributeName": "SerialNumber", "KeyType": "HASH" },
        { "AttributeName": "DeviceUniqueId", "KeyType": "RANGE" }
    ],
    "AttributeDefinitions": [
        { "AttributeName": "SerialNumber", "AttributeType": "S" },
        { "AttributeName": "DeviceUniqueId", "AttributeType": "S" }
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "DeviceUniqueIdIndex",
            "KeySchema": [
                { "AttributeName": "DeviceUniqueId", "KeyType": "HASH" }
            ],
            "Projection": {
              "ProjectionType": "ALL"
            },
            "ProvisionedThroughput": {
                "ReadCapacityUnits": 5,
                "WriteCapacityUnits": 5
            }
        }
    ],
    "BillingMode": "PAY_PER_REQUEST"
}
EOF
)
awslocal dynamodb create-table --cli-input-json "${DYNAMO_DEVICE_REGISTRY}"
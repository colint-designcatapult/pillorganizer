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

DYNAMO_CONTROL_PLANE=$(cat <<EOF
{
    "TableName": "DeviceControlPlane",
    "KeySchema": [
        { "AttributeName": "PK", "KeyType": "HASH" },
        { "AttributeName": "SK", "KeyType": "RANGE" }
    ],
    "AttributeDefinitions": [
        { "AttributeName": "PK", "AttributeType": "S" },
        { "AttributeName": "SK", "AttributeType": "S" },
        { "AttributeName": "GSI1_PK", "AttributeType": "S" },
        { "AttributeName": "GSI1_SK", "AttributeType": "S" },
        { "AttributeName": "GSI2_PK", "AttributeType": "S" },
        { "AttributeName": "GSI2_SK", "AttributeType": "S" }
    ],
    "GlobalSecondaryIndexes": [
        {
            "IndexName": "GSI1",
            "KeySchema": [
                { "AttributeName": "GSI1_PK", "KeyType": "HASH" },
                { "AttributeName": "GSI1_SK", "KeyType": "RANGE" }
            ],
            "Projection": {
              "ProjectionType": "ALL"
            }
        },
        {
            "IndexName": "GSI2",
            "KeySchema": [
                { "AttributeName": "GSI2_PK", "KeyType": "HASH" },
                { "AttributeName": "GSI2_SK", "KeyType": "RANGE" }
            ],
            "Projection": {
              "ProjectionType": "ALL"
            }
        }
    ],
    "BillingMode": "PAY_PER_REQUEST"
}
EOF
)
awslocal dynamodb create-table --cli-input-json "${DYNAMO_CONTROL_PLANE}"

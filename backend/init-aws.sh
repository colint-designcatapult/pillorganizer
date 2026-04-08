#!/bin/bash

# Use ca-central-1 Canadian region
export AWS_DEFAULT_REGION=ca-central-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# Variable to control whether this is local/test, etc
# Defaults to local if not set in environment variable already
: "${ENVIRONMENT_KEY:=local}"

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
aws dynamodb create-table --endpoint-url http://localhost:8000 --cli-input-json "${DYNAMO_CONTROL_PLANE}"

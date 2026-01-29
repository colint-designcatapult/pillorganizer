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
    --description "Local development database credentials" \
    --secret-string "${DB_SECRET_JSON}"
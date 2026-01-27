#!/bin/bash

# Use ca-central-1 Canadian region
export AWS_DEFAULT_REGION=ca-central-1

# Build secret in RDS format
DB_SECRET_JSON=$(cat <<EOF
{
  "username": "postgres",
  "password": "root",
  "engine": "postgres",
  "host": "localhost",
  "port": 5432,
  "dbInstanceIdentifier": "local-db"
}
EOF
)

awslocal secretsmanager create-secret \
    --name /config/pillorganizer-backend/database \
    --description "Local development database credentials" \
    --secret-string "${DB_SECRET_JSON}"
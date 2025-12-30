#!/usr/bin/env bash

set -e
set -o pipefail
set -u

region="$REGION"
secret_arn="$SECRET_ARN"
name="$TARGET_NAME"
namespace="$TARGET_NAMESPACE"
db_address="$DB_ADDRESS"
db_port="$DB_PORT"
db_name="$DB_NAME"

echo "[rds-secrets import] kubectl auth whoami"
echo "pwd: $(pwd)"
kubectl auth whoami -o json | jq -c

echo "[rds-secrets import] reading db access secrets from AWS Secrets Manager"
secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$secret_arn")
username=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
password=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

# URL-encode the password (special characters break connection string parsing)
encoded_password=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$password', safe=''))")

# Build connection URL
# postgres://username:password@hostname:port/database?sslmode=disable
connection_url="postgres://${username}:${encoded_password}@${db_address}:${db_port}/${db_name}?sslmode=disable"

echo "[rds-secrets import] creating namespace if not exists"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[rds-secrets import] creating RDS access secret"
kubectl create -n "$namespace" secret generic "$name" \
  --save-config    \
  --dry-run=client \
  --from-literal=username="$username" \
  --from-literal=password="$password" \
  --from-literal=url="$connection_url" \
  -o yaml | kubectl apply -f -

echo "[rds-secrets import] secret created successfully"

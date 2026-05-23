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

echo "[rds-creds] kubectl auth whoami"
kubectl auth whoami -o json | jq -c

echo "[rds-creds] reading RDS master secret from Secrets Manager"
secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$secret_arn")
username=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
password=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

encoded_password=$(printf '%s' "$password" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')

connection_url="postgres://${username}:${encoded_password}@${db_address}:${db_port}/${db_name}"
direct_url="$connection_url"

echo "[rds-creds] ensuring namespace exists"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[rds-creds] writing secret ${name} in namespace ${namespace}"
kubectl create -n "$namespace" secret generic "$name" \
  --save-config    \
  --dry-run=client \
  --from-literal=username="$username" \
  --from-literal=password="$password" \
  --from-literal=database="$db_name" \
  --from-literal=host="$db_address" \
  --from-literal=port="$db_port" \
  --from-literal=url="$connection_url" \
  --from-literal=direct-url="$direct_url" \
  -o yaml | kubectl apply -f -

echo "[rds-creds] done"

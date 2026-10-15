#!/usr/bin/env bash

set -euo pipefail

region="$REGION"
secret_arn="$SECRET_ARN"
namespace="$TARGET_NAMESPACE"
name="$TARGET_NAME"
db_address="$DB_ADDRESS"
db_port="$DB_PORT"
db_name="$DB_NAME"
bucket_name="$BUCKET_NAME"
persist_prefix="$PERSIST_PREFIX"
license_secret="$LICENSE_SECRET"
license_key_name="$LICENSE_KEY_NAME"

echo "[backend-secret] kubectl auth whoami"
kubectl auth whoami -o json | jq -c

echo "[backend-secret] ensuring namespace exists"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[backend-secret] reading RDS master secret from Secrets Manager"
secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$secret_arn")
username=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
password=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')
encoded_password=$(printf '%s' "$password" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')

metadata_backend_url="postgres://${username}:${encoded_password}@${db_address}:${db_port}/${db_name}?sslmode=require&options=-c%20statement_timeout%3D15min"
persist_backend_url="s3://${bucket_name}/${persist_prefix}"

echo "[backend-secret] waiting for license secret ${license_secret}"
for i in $(seq 1 30); do
  if kubectl -n "$namespace" get secret "$license_secret" >/dev/null 2>&1; then
    break
  fi
  if [[ "$i" -eq 30 ]]; then
    echo "[backend-secret] license secret ${license_secret} not found; ensure the Nuon license_key secret is configured" >&2
    exit 1
  fi
  sleep 2
done

license_key=$(kubectl -n "$namespace" get secret "$license_secret" -o json | jq -r --arg k "$license_key_name" '.data[$k] // empty' | base64 -d)
if [[ -z "$license_key" ]]; then
  echo "[backend-secret] license key missing in secret ${license_secret}" >&2
  exit 1
fi


mz_system_password=""
if kubectl -n "$namespace" get secret "$name" >/dev/null 2>&1; then
  mz_system_password=$(kubectl -n "$namespace" get secret "$name" -o jsonpath='{.data.external_login_password_mz_system}' | base64 -d || true)
fi
if [[ -z "$mz_system_password" ]]; then
  mz_system_password=$(openssl rand -hex 16)
fi

echo "[backend-secret] writing secret ${name} in namespace ${namespace}"
kubectl create -n "$namespace" secret generic "$name" \
  --save-config \
  --dry-run=client \
  --from-literal=metadata_backend_url="$metadata_backend_url" \
  --from-literal=persist_backend_url="$persist_backend_url" \
  --from-literal=license_key="$license_key" \
  --from-literal=external_login_password_mz_system="$mz_system_password" \
  -o yaml | kubectl apply -f -

echo "[backend-secret] done"

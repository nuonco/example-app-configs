#!/usr/bin/env bash

set -e
set -o pipefail
set -u

username="$DB_USERNAME"
password="$DB_PASSWORD"
db_address="$DB_ADDRESS"
db_port="$DB_PORT"
db_name="$DB_NAME"
name="$TARGET_NAME"
namespace="$TARGET_NAMESPACE"

echo "[coder-db-creds] kubectl auth whoami"
kubectl auth whoami -o json | jq -c

# URL-encode the password (special characters break connection string parsing)
encoded_password=$(printf '%s' "$password" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')

# postgres://username:password@hostname:port/database?sslmode=disable
connection_url="postgres://${username}:${encoded_password}@${db_address}:${db_port}/${db_name}?sslmode=disable"

echo "[coder-db-creds] creating namespace if not exists"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[coder-db-creds] creating Coder DB url secret"
kubectl create -n "$namespace" secret generic "$name" \
  --save-config    \
  --dry-run=client \
  --from-literal=username="$username" \
  --from-literal=password="$password" \
  --from-literal=url="$connection_url" \
  -o yaml | kubectl apply -f -

# Mirror the password into the observability namespace for the postgres exporter.
observability_namespace="coder-observability"
observability_secret_name="coder-db-password"

echo "[coder-db-creds] creating observability namespace if not exists"
kubectl create namespace "$observability_namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[coder-db-creds] mirroring password to observability namespace"
kubectl create -n "$observability_namespace" secret generic "$observability_secret_name" \
  --save-config \
  --dry-run=client \
  --from-literal=PGPASSWORD="$password" \
  -o yaml | kubectl apply -f -

echo "[coder-db-creds] done"

#!/usr/bin/env bash

set -euo pipefail

username="$DB_USERNAME"
password="$DB_PASSWORD"
name="$TARGET_NAME"
namespace="$TARGET_NAMESPACE"

echo "[sonar-db-creds] kubectl auth whoami"
kubectl auth whoami -o json | jq -c

echo "[sonar-db-creds] creating namespace if not exists"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[sonar-db-creds] creating SonarQube JDBC password secret"
kubectl create -n "$namespace" secret generic "$name" \
  --save-config \
  --dry-run=client \
  --from-literal=username="$username" \
  --from-literal=password="$password" \
  -o yaml | kubectl apply -f -

echo "[sonar-db-creds] done"

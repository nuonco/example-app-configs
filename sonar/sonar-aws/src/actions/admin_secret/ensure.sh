#!/usr/bin/env bash

set -euo pipefail

namespace="$TARGET_NAMESPACE"
name="$TARGET_NAME"

echo "[admin-secret] ensuring $namespace/$name has password + currentPassword keys"

kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

if ! kubectl get secret -n "$namespace" "$name" >/dev/null 2>&1; then
  echo "[admin-secret] secret $name not found; waiting for Nuon kubernetes sync of admin_password" >&2
  exit 1
fi

password=$(kubectl get secret -n "$namespace" "$name" -o jsonpath='{.data.password}' | base64 -d)
if [ -z "$password" ]; then
  echo "[admin-secret] password key empty on $name" >&2
  exit 1
fi

kubectl create -n "$namespace" secret generic "$name" \
  --save-config \
  --dry-run=client \
  --from-literal=password="$password" \
  --from-literal=currentPassword=admin \
  -o yaml | kubectl apply -f -

echo "[admin-secret] secret ready"
jq --null-input -c \
  --arg name "$name" \
  --arg namespace "$namespace" \
  --arg updated_at "$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)" \
  '{name: $name, namespace: $namespace, state: "ready", updated_at: $updated_at}' \
  >> "$NUON_ACTIONS_OUTPUT_FILEPATH"

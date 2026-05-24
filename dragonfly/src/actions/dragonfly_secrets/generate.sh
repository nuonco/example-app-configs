#!/usr/bin/env bash

# Idempotent. Generates a 32-byte hex AUTH password and writes it to
# secret/dragonfly-auth (key=password) in the dragonfly namespace.
# No-op when auth is disabled. Rotating an existing password would lock
# every client out until they reconnect with the new value, so an
# existing secret is left in place.

set -e
set -o pipefail
set -u

namespace="$TARGET_NAMESPACE"
secret_name="dragonfly-auth"

if [ "${AUTH_ENABLED:-false}" != "true" ]; then
  echo "[dragonfly-secrets] auth disabled, skipping"
  exit 0
fi

echo "[dragonfly-secrets] ensuring namespace ${namespace}"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

if kubectl get secret "$secret_name" -n "$namespace" >/dev/null 2>&1; then
  echo "[dragonfly-secrets] ${secret_name} already exists, leaving in place"
else
  echo "[dragonfly-secrets] generating ${secret_name}"
  password=$(openssl rand -hex 32)
  kubectl create -n "$namespace" secret generic "$secret_name" \
    --from-literal=password="$password"
fi

echo "[dragonfly-secrets] done"

#!/usr/bin/env bash

# Generates a ClickHouse password and writes the same Secret into two namespaces:
#   - clickhouse: read by the Altinity ClickHouseInstallation CR to bootstrap the default user
#   - langfuse:   read by the Langfuse Helm release via clickhouse.auth.existingSecret
#
# Idempotent: if the secret already exists in the clickhouse namespace, the
# existing password is reused (so the langfuse copy stays in sync). Rotating
# the ClickHouse password would orphan the data on disk, so don't rotate
# implicitly.

set -e
set -o pipefail
set -u

ch_ns="$CLICKHOUSE_NAMESPACE"
lf_ns="$LANGFUSE_NAMESPACE"
name="$SECRET_NAME"
username="$CH_USERNAME"

echo "[clickhouse-creds] ensuring namespaces"
kubectl create namespace "$ch_ns" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace "$lf_ns" --dry-run=client -o yaml | kubectl apply -f -

if kubectl get secret "$name" -n "$ch_ns" >/dev/null 2>&1; then
  echo "[clickhouse-creds] reading existing password from ${ch_ns}/${name}"
  password=$(kubectl get secret "$name" -n "$ch_ns" -o jsonpath='{.data.password}' | base64 -d)
else
  echo "[clickhouse-creds] generating new password and writing to ${ch_ns}/${name}"
  password=$(openssl rand -hex 24)
  kubectl create -n "$ch_ns" secret generic "$name" \
    --from-literal=username="$username" \
    --from-literal=password="$password"
fi

echo "[clickhouse-creds] propagating to ${lf_ns}/${name}"
kubectl create -n "$lf_ns" secret generic "$name" \
  --save-config    \
  --dry-run=client \
  --from-literal=username="$username" \
  --from-literal=password="$password" \
  -o yaml | kubectl apply -f -

echo "[clickhouse-creds] done"

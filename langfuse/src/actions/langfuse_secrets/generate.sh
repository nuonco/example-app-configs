#!/usr/bin/env bash

# Generates and persists the Langfuse application secret:
#   langfuse-secrets:
#     - salt (base64 32-byte)             — hashes API keys
#     - nextauth-secret (hex 32-byte)     — NextAuth JWT signing
#     - encryption-key (hex 32-byte, exactly 64 hex chars) — encrypts sensitive columns
#     - init-public-key   (pk-lf-{hex32}) — used by Langfuse headless init + demo action
#     - init-secret-key   (sk-lf-{hex64}) — paired with init-public-key
#     - init-user-password (hex 24-byte)  — admin account bootstrapped by headless init
#
# Redis credentials are NOT generated here: ElastiCache (Valkey) runs without
# auth for the demo, gated by the private subnet + security group.
#
# Idempotent: existing secrets are left alone. Rotating encryption-key would
# break reads of previously-encrypted columns; rotating init-* keys would
# orphan any traces already ingested with the old key. Don't rotate implicitly.

set -e
set -o pipefail
set -u

namespace="$TARGET_NAMESPACE"
langfuse_secret_name="langfuse-secrets"

echo "[langfuse-secrets] ensuring namespace ${namespace}"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

if kubectl get secret "$langfuse_secret_name" -n "$namespace" >/dev/null 2>&1; then
  echo "[langfuse-secrets] ${langfuse_secret_name} already exists, leaving in place"
else
  echo "[langfuse-secrets] generating ${langfuse_secret_name}"
  salt=$(openssl rand -base64 32)
  nextauth_secret=$(openssl rand -hex 32)
  encryption_key=$(openssl rand -hex 32)
  init_public_key="pk-lf-$(openssl rand -hex 16)"
  init_secret_key="sk-lf-$(openssl rand -hex 32)"
  init_user_password=$(openssl rand -hex 24)

  if [ "${#encryption_key}" -ne 64 ]; then
    echo "[langfuse-secrets] ERROR: encryption_key must be 64 hex chars, got ${#encryption_key}" >&2
    exit 1
  fi

  kubectl create -n "$namespace" secret generic "$langfuse_secret_name" \
    --from-literal=salt="$salt" \
    --from-literal=nextauth-secret="$nextauth_secret" \
    --from-literal=encryption-key="$encryption_key" \
    --from-literal=init-public-key="$init_public_key" \
    --from-literal=init-secret-key="$init_secret_key" \
    --from-literal=init-user-password="$init_user_password"
fi

echo "[langfuse-secrets] done"

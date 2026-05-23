#!/usr/bin/env bash

# Generates and persists the four secrets Langfuse needs at runtime:
#   - SALT (base64 32-byte)             — hashes API keys
#   - NEXTAUTH_SECRET (hex 32-byte)     — NextAuth JWT signing
#   - ENCRYPTION_KEY (hex 32-byte, exactly 64 hex chars) — encrypts sensitive columns
#   - Redis password (URL-safe random)  — for in-cluster Redis
#
# Idempotent: if the secrets already exist, this script leaves them alone.
# Rotating ENCRYPTION_KEY would break reads of previously-encrypted columns,
# so re-running this action MUST NOT replace existing secrets.

set -e
set -o pipefail
set -u

namespace="$TARGET_NAMESPACE"
langfuse_secret_name="langfuse-secrets"
redis_secret_name="langfuse-redis"

echo "[langfuse-secrets] ensuring namespace ${namespace}"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

if kubectl get secret "$langfuse_secret_name" -n "$namespace" >/dev/null 2>&1; then
  echo "[langfuse-secrets] ${langfuse_secret_name} already exists, leaving in place"
else
  echo "[langfuse-secrets] generating ${langfuse_secret_name}"
  salt=$(openssl rand -base64 32)
  nextauth_secret=$(openssl rand -hex 32)
  encryption_key=$(openssl rand -hex 32)

  if [ "${#encryption_key}" -ne 64 ]; then
    echo "[langfuse-secrets] ERROR: encryption_key must be 64 hex chars, got ${#encryption_key}" >&2
    exit 1
  fi

  kubectl create -n "$namespace" secret generic "$langfuse_secret_name" \
    --from-literal=salt="$salt" \
    --from-literal=nextauth-secret="$nextauth_secret" \
    --from-literal=encryption-key="$encryption_key"
fi

if kubectl get secret "$redis_secret_name" -n "$namespace" >/dev/null 2>&1; then
  echo "[langfuse-secrets] ${redis_secret_name} already exists, leaving in place"
else
  echo "[langfuse-secrets] generating ${redis_secret_name}"
  # URL-safe: avoid characters that break redis-cli or URL-style connection strings
  redis_password=$(openssl rand -hex 24)

  kubectl create -n "$namespace" secret generic "$redis_secret_name" \
    --from-literal=password="$redis_password"
fi

echo "[langfuse-secrets] done"

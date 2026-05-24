#!/usr/bin/env bash

set -e
set -o pipefail
set -u

namespace="$TARGET_NAMESPACE"
pod="dragonfly-0"

args=()
if [ "${AUTH_ENABLED:-false}" = "true" ]; then
  password=$(kubectl get secret dragonfly-auth -n "$namespace" -o jsonpath='{.data.password}' | base64 -d)
  args+=(-a "$password" --no-auth-warning)
fi

echo "[health-check] kubectl exec ${pod} -- redis-cli PING"
result=$(kubectl exec -n "$namespace" "$pod" -c dragonfly -- redis-cli "${args[@]}" PING)

echo "[health-check] result=${result}"
if [ "$result" != "PONG" ]; then
  echo "[health-check] FAIL: expected PONG, got '${result}'" >&2
  exit 1
fi

echo "[health-check] OK"

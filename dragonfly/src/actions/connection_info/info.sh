#!/usr/bin/env bash

set -e
set -o pipefail
set -u

namespace="$TARGET_NAMESPACE"
scheme="redis"
if [ "${TLS_ENABLED:-false}" = "true" ]; then
  scheme="rediss"
fi

echo "[connection-info] in-cluster endpoint:"
echo "  ${scheme}://dragonfly.${namespace}.svc.cluster.local:6379"
echo

if [ "${AUTH_ENABLED:-false}" = "true" ]; then
  echo "[connection-info] AUTH required. Retrieve the password with:"
  echo "  kubectl get secret dragonfly-auth -n ${namespace} -o jsonpath='{.data.password}' | base64 -d"
  echo
fi

echo "[connection-info] service:"
kubectl get svc -n "$namespace" -l app.kubernetes.io/part-of=dragonfly-operator 2>/dev/null || true

echo
echo "[connection-info] pods:"
kubectl get pods -n "$namespace" -l app.kubernetes.io/part-of=dragonfly-operator 2>/dev/null || true

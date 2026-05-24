#!/usr/bin/env bash

# On-demand snapshot. Issues redis-cli SAVE inside the dragonfly pod,
# which writes a snapshot file to the configured spec.snapshot.dir
# (s3://${BUCKET_NAME}/snapshots/).

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

echo "[trigger-snapshot] kubectl exec ${pod} -- redis-cli SAVE"
kubectl exec -n "$namespace" "$pod" -c dragonfly -- redis-cli "${args[@]}" SAVE

echo "[trigger-snapshot] snapshot complete. recent objects:"
aws s3 ls "s3://${BUCKET_NAME}/snapshots/" --recursive --region "${AWS_REGION}" | tail -5 || true

echo "[trigger-snapshot] OK"

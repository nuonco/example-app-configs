#!/usr/bin/env bash

# Destructive. Restores the most recent S3 snapshot by deleting the
# dragonfly pod; the operator's recreated pod loads the latest snapshot
# in spec.snapshot.dir on startup. In-memory state since the last
# snapshot is lost. Requires CONFIRM=YES.

set -e
set -o pipefail
set -u

if [ "${CONFIRM:-}" != "YES" ]; then
  echo "[restore] refusing to run: set CONFIRM=YES to proceed" >&2
  echo "[restore] this will discard in-memory state since the last snapshot." >&2
  exit 1
fi

namespace="$TARGET_NAMESPACE"
pod="dragonfly-0"

echo "[restore] snapshot inventory in s3://${BUCKET_NAME}/snapshots/:"
aws s3 ls "s3://${BUCKET_NAME}/snapshots/" --recursive --region "${AWS_REGION}" | tail -10 || true

echo "[restore] deleting pod ${pod}; operator will recreate and reload latest snapshot"
kubectl delete pod -n "$namespace" "$pod" --wait=true --timeout=120s

echo "[restore] waiting for ${pod} to become ready"
kubectl wait --for=condition=Ready -n "$namespace" "pod/${pod}" --timeout=180s

echo "[restore] OK"

#!/usr/bin/env bash

set -e
set -o pipefail
set -u

url="${LANGFUSE_URL%/}/api/public/health"

echo "[health-check] GET ${url}"

http_status=$(curl -fsS -o /tmp/health.json -w '%{http_code}' "$url" || echo "000")

echo "[health-check] http_status=${http_status}"
if [ -f /tmp/health.json ]; then
  echo "[health-check] body:"
  cat /tmp/health.json
  echo
fi

if [ "$http_status" != "200" ]; then
  echo "[health-check] FAIL: expected 200, got ${http_status}" >&2
  exit 1
fi

echo "[health-check] OK"

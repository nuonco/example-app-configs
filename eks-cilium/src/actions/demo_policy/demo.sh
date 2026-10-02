#!/usr/bin/env bash
set -euo pipefail

NS="${NAMESPACE:-cilium-demo}"

pod_for() {
  kubectl -n "$NS" get pod -l "class=$1" \
    -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}'
}

TIE="$(pod_for tiefighter)"
XWING="$(pod_for xwing)"

# curl exits non-zero when the request is dropped, which is the expected result
# for two of these three calls — so each is reported rather than aborting the run.
try() {
  local label="$1" pod="$2"
  shift 2
  echo "--- $label"
  if out="$(kubectl -n "$NS" exec "$pod" -- curl -sS --max-time 8 "$@" 2>&1)"; then
    echo "    ALLOWED: ${out:-<empty response>}"
  else
    echo "    DENIED:  ${out:-timed out / connection refused}"
  fi
  echo
}

echo "=== L3/L4: identity decides who may reach the deathstar ==="
try "tiefighter (org=empire) -> deathstar" "$TIE" \
  -XPOST http://deathstar.$NS.svc.cluster.local/v1/request-landing
try "xwing (org=alliance) -> deathstar" "$XWING" \
  -XPOST http://deathstar.$NS.svc.cluster.local/v1/request-landing

echo "=== L7: the same allowed caller is still restricted by method and path ==="
try "tiefighter -> PUT /v1/exhaust-port" "$TIE" \
  -XPUT http://deathstar.$NS.svc.cluster.local/v1/exhaust-port

echo "Expected: the first call succeeds, the second is dropped on identity before"
echo "any HTTP is parsed, and the third is refused by the L7 filter even though"
echo "the caller is allowed at L3/L4."

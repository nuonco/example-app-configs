#!/usr/bin/env bash
set -euo pipefail

NS="${NAMESPACE:-cilium-demo}"
ALLOWED="${ALLOWED_FQDN:-cilium.io}"
BLOCKED="${BLOCKED_FQDN:-example.com}"

POD="$(kubectl -n "$NS" get pod -l class=smuggler \
  -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')"

try() {
  local label="$1" host="$2"
  echo "--- $label ($host)"
  if out="$(kubectl -n "$NS" exec "$POD" -- \
      curl -sS -o /dev/null -w '%{http_code}' --max-time 8 "https://$host" 2>&1)"; then
    echo "    ALLOWED: HTTP $out"
  else
    echo "    DENIED:  ${out:-timed out}"
  fi
  echo
}

echo "=== DNS-aware egress: the smuggler may only reach one name ==="
try "allowed by toFQDNs" "$ALLOWED"
try "not in the allow list" "$BLOCKED"

echo "=== what cilium learned from the DNS responses ==="
kubectl -n kube-system exec ds/cilium -c cilium-agent -- \
  cilium-dbg fqdn cache list 2>/dev/null | head -20 \
  || kubectl -n kube-system exec ds/cilium -- cilium fqdn cache list 2>/dev/null | head -20 \
  || echo "  (fqdn cache unavailable)"

echo
echo "Both names resolve — DNS is allowed so the policy can observe it. Only the"
echo "IPs behind the allowed name are then permitted, which is why the second"
echo "request fails after a successful lookup rather than failing to resolve."

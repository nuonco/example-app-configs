#!/usr/bin/env bash
set -euo pipefail

NS="${NAMESPACE:-cilium-demo}"
LIMIT="${FLOW_LIMIT:-30}"

# hubble ships inside the agent image, so no extra tooling is needed on the runner.
hubble() {
  kubectl -n kube-system exec ds/cilium -c cilium-agent -- hubble "$@" 2>/dev/null \
    || kubectl -n kube-system exec ds/cilium -- hubble "$@"
}

echo "=== dropped flows in $NS ==="
hubble observe --namespace "$NS" --verdict DROPPED --last "$LIMIT" || true

echo
echo "=== L7 HTTP flows in $NS ==="
hubble observe --namespace "$NS" --protocol http --last "$LIMIT" || true

echo
echo "=== all recent verdicts in $NS ==="
hubble observe --namespace "$NS" --last "$LIMIT" || true

echo
echo "Flows are labelled by Cilium identity rather than IP, so the verdict names"
echo "the workload that was allowed or dropped. The same view is in Hubble UI."

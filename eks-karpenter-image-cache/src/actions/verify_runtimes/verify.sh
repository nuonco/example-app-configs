#!/usr/bin/env bash
set -euo pipefail

NS="${NAMESPACE:-whoami}"

report() {
  local app="$1" pod node
  pod="$(kubectl -n "$NS" get pod -l "app=$app" \
    -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')"
  if [ -z "$pod" ]; then
    echo "  no running pod for app=$app"
    return 1
  fi
  node="$(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.nodeName}')"

  echo "  pod:            $pod"
  echo "  node:           $node"
  echo "  runtimeClass:   $(kubectl -n "$NS" get pod "$pod" -o jsonpath='{.spec.runtimeClassName}' || true)"
  echo "  uname -r:       $(kubectl -n "$NS" exec "$pod" -c kernel -- uname -r)"
  echo "  /proc/version:  $(kubectl -n "$NS" exec "$pod" -c kernel -- cat /proc/version)"
  echo "  dmesg (first 3 lines):"
  kubectl -n "$NS" exec "$pod" -c kernel -- dmesg 2>/dev/null | head -3 | sed 's/^/    /' || echo "    (unavailable)"
}

echo "=== RuntimeClass ==="
kubectl get runtimeclass gvisor -o jsonpath='{.metadata.name}{"\t"}{.handler}{"\n"}'

echo
echo "=== whoami (runc) ==="
report whoami

echo
echo "=== whoami-gvisor (runsc) ==="
report whoami-gvisor

echo
echo "=== node runtime ==="
kubectl get nodes -l nuon.co/node-pool=cached \
  -o custom-columns='NODE:.metadata.name,RUNTIME:.status.nodeInfo.containerRuntimeVersion,KERNEL:.status.nodeInfo.kernelVersion'

echo
echo "=== pods ==="
kubectl -n "$NS" get pods -o custom-columns='POD:.metadata.name,NODE:.spec.nodeName,RUNTIMECLASS:.spec.runtimeClassName,STATUS:.status.phase'

echo
echo "Both pods should report the same node. whoami reports the host AL2023"
echo "kernel; whoami-gvisor reports gVisor's synthetic kernel. The same output"
echo "is served in a browser at /kernel on each host."

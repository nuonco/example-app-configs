#!/usr/bin/env bash
set -euo pipefail

echo "=== nodes ==="
kubectl get nodes -o custom-columns='NODE:.metadata.name,STATUS:.status.conditions[-1].type,RUNTIME:.status.nodeInfo.containerRuntimeVersion,KERNEL:.status.nodeInfo.kernelVersion'

echo
echo "=== vpc cni / kube-proxy should both be absent ==="
for ds in aws-node kube-proxy; do
  if kubectl -n kube-system get ds "$ds" >/dev/null 2>&1; then
    echo "  $ds: PRESENT — cilium is not the sole CNI"
  else
    echo "  $ds: absent"
  fi
done

echo
echo "=== cilium daemonset ==="
kubectl -n kube-system get ds cilium -o custom-columns='NAME:.metadata.name,DESIRED:.status.desiredNumberScheduled,READY:.status.numberReady'

echo
echo "=== cilium status ==="
kubectl -n kube-system exec ds/cilium -c cilium-agent -- cilium-dbg status --brief 2>/dev/null \
  || kubectl -n kube-system exec ds/cilium -- cilium status --brief

echo
echo "=== datapath config ==="
kubectl -n kube-system get cm cilium-config \
  -o jsonpath='{range .data}{"ipam            = "}{.ipam}{"\n"}{"routing-mode    = "}{.routing-mode}{"\n"}{"kube-proxy-repl = "}{.kube-proxy-replacement}{"\n"}{end}'

echo
echo "=== pod IPs should be VPC addresses (ENI IPAM) ==="
kubectl -n cilium-demo get pods -o custom-columns='POD:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName'

echo
echo "=== cilium endpoints and their identities ==="
kubectl -n cilium-demo get cep -o custom-columns='ENDPOINT:.metadata.name,IDENTITY:.status.identity.id,IP:.status.networking.addressing[0].ipv4' 2>/dev/null || true

echo
echo "=== policies in force ==="
kubectl -n cilium-demo get cnp

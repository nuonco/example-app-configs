#!/bin/bash

set -e
set -o pipefail
set -u

TAILNET="" # default value
NAMESPACE="clickhouse"

echo "looking for ingresses in namespace: $NAMESPACE"
ingresses=`kubectl get ingress -n "$NAMESPACE" -o json | jq -c`
echo "filtering down to tailscale ingresses"
tailscale_ingresses=`echo "$ingresses" | jq -c '.items[] | select(.spec.ingressClassName == "tailscale")'`
if [ -z "$tailscale_ingresses" ]; then
    echo "Error: No Tailscale ingresses found in namespace ${NAMESPACE}" >&2
    exit 1
fi

# Get the first ingress with tailscale className
# Use jq to get first item directly to avoid SIGPIPE from head
ingress_name=`kubectl get ingress -n "$NAMESPACE" -o json | jq -r '[.items[] | select(.spec.ingressClassName == "tailscale")][0].metadata.name'`

echo "found ingress: ${ingress_name}"

# Get the Tailscale hostname from the ingress status
ingress_hostname=$(kubectl get ingress "${ingress_name}" -n "${NAMESPACE}" -o json | \
    jq -r '.status.loadBalancer.ingress[0].hostname // empty')

if [ -z "$ingress_hostname" ]; then
    echo "Warning: Tailscale hostname not yet available for ingress ${ingress_name}" >&2
    echo "The ingress may still be provisioning. Please wait a moment and try again." >&2
    exit 1
fi

# Extract tailnet address by removing the subdomain (first part before first dot)
# Example: subdomain.tailnetxx.ts.net -> tailnetxx.ts.net
TAILNET=`echo "${ingress_hostname}" | cut -d'.' -f2-`

echo "Full hostname: ${ingress_hostname}"
echo "Tailnet address: ${TAILNET}"

echo '{"tailnet": "'$TAILNET'"}' >> $NUON_ACTIONS_OUTPUT_FILEPATH

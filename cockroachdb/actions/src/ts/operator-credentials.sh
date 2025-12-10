#!/usr/bin/env sh

# if tailscale is enabled, secrets are expected to have been created during the cloudformation stack creation
# those secrets would have been copied into the cluster according the configs in secrets/*/*.toml
# this action acts on those kubernetes secrets

set -e
set -o pipefail
set -u

ts_enabled="$TS_ENABLED"

# if not ts_enable, log and exit
if [[ $ts_enabled == "true" ]]; then
  echo "[enabled] will munge secrets"
  oauth_client_id=`kubectl get -n tailscale secret tailscale-oauth-client-id -o json | jq -r '.data.value' | base64 -d`
  oauth_client_secret=`kubectl get -n tailscale secret tailscale-oauth-client-secret -o json | jq -r '.data.value' | base64 -d`
  kubectl create -n tailscale secret generic operator-oauth \
    --save-config    \
    --dry-run=client \
    --from-literal=client_id="$oauth_client_id" \
    --from-literal=client_secret="$oauth_client_secret" \
    -o yaml | kubectl apply -f -
else
  echo "[disabled] doing nothing"
fi

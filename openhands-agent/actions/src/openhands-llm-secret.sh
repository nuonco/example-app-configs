#!/usr/bin/env sh

# the llm secret api key will have been copied into the cluster according the configs in secrets/*/*.toml
# this action acts on those kubernetes secrets

set -e
set -o pipefail
set -u

echo "fetching secret"
value=`kubectl get -n openhands secret llm-api-key -o json | jq -r '.data.value' | base64 -d`

echo "munging secret into new secret"
kubectl create -n openhands secret generic openhands \
  --save-config    \
  --dry-run=client \
  --from-literal=OPENHANDS_LLM_API_KEY="$value" \
  -o yaml | kubectl apply -f -

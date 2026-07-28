#!/usr/bin/env sh
set -eu

FULL_TAG='{{.runbook_inputs.image_tag}}'
[ "${NUON_KUBECONFIG_ENABLED:-false}" = "true" ] || { echo "Kubernetes access is unavailable"; exit 1; }

kubectl create configmap nuon-event-image-tag \
  --namespace default \
  --from-literal=image="$FULL_TAG" \
  --dry-run=client -o yaml | kubectl apply -f -

RECORDED_TAG=$(kubectl get configmap nuon-event-image-tag --namespace default -o jsonpath='{.data.image}')
[ "$RECORDED_TAG" = "$FULL_TAG" ] || { echo "Recorded tag mismatch"; exit 1; }

echo "Recorded approved event image in Kubernetes: $RECORDED_TAG"
printf '{"image":"%s"}\n' "$RECORDED_TAG" >> "$NUON_ACTIONS_OUTPUT_FILEPATH"

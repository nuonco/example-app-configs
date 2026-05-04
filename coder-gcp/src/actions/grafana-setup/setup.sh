#!/usr/bin/env bash

set -e
set -o pipefail
set -u

project_id="$PROJECT_ID"
install_id="$INSTALL_ID"
grafana_secret_id="grafana-admin-${install_id}"
grafana_username="admin"
observability_namespace="coder-observability"

echo "[grafana-setup] creating namespace if not exists"
kubectl create namespace "$observability_namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[grafana-setup] checking if Grafana admin secret exists in Secret Manager"
if gcloud --project "$project_id" secrets describe "$grafana_secret_id" >/dev/null 2>&1; then
  echo "[grafana-setup] Grafana admin secret already exists, retrieving"
  grafana_password=$(gcloud --project "$project_id" secrets versions access latest --secret="$grafana_secret_id" \
    | jq -r '.password')
else
  echo "[grafana-setup] generating new Grafana admin password"
  grafana_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

  echo "[grafana-setup] creating Grafana admin secret in Secret Manager"
  payload=$(jq -nc --arg u "$grafana_username" --arg p "$grafana_password" '{username: $u, password: $p}')
  printf '%s' "$payload" | gcloud --project "$project_id" secrets create "$grafana_secret_id" \
    --replication-policy=automatic \
    --labels="install-nuon-co-id=${install_id},component=observability" \
    --data-file=-
fi

echo "[grafana-setup] creating Grafana admin secret in Kubernetes"
kubectl create -n "$observability_namespace" secret generic grafana-admin \
  --save-config \
  --dry-run=client \
  --from-literal=username="$grafana_username" \
  --from-literal=password="$grafana_password" \
  -o yaml | kubectl apply -f -

echo "[grafana-setup] done"

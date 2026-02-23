#!/usr/bin/env bash

set -e
set -o pipefail
set -u

region="$REGION"
install_id="$INSTALL_ID"
grafana_secret_name="grafana-admin-${install_id}"
grafana_username="admin"
observability_namespace="coder-observability"

echo "[grafana-setup] creating namespace if not exists"
kubectl create namespace "$observability_namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[grafana-setup] checking if Grafana admin secret exists in Secrets Manager"
if aws --region "$region" secretsmanager describe-secret --secret-id="$grafana_secret_name" 2>/dev/null; then
  echo "[grafana-setup] Grafana admin secret already exists, retrieving"
  grafana_secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$grafana_secret_name")
  grafana_password=$(echo "$grafana_secret" | jq -r '.SecretString' | jq -r '.password')
else
  echo "[grafana-setup] generating new Grafana admin password"
  grafana_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

  echo "[grafana-setup] storing Grafana admin password in Secrets Manager"
  aws --region "$region" secretsmanager create-secret \
    --name "$grafana_secret_name" \
    --description "Grafana admin credentials for Nuon install ${install_id}" \
    --secret-string "{\"username\":\"${grafana_username}\",\"password\":\"${grafana_password}\"}" \
    --tags Key=nuon-install-id,Value="${install_id}" Key=component,Value=observability
fi

echo "[grafana-setup] creating Grafana admin secret in Kubernetes"
kubectl create -n "$observability_namespace" secret generic grafana-admin \
  --save-config \
  --dry-run=client \
  --from-literal=username="$grafana_username" \
  --from-literal=password="$grafana_password" \
  -o yaml | kubectl apply -f -

echo "[grafana-setup] Grafana admin secret created successfully"

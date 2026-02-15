#!/usr/bin/env bash

set -e
set -o pipefail
set -u

region="$REGION"
secret_arn="$SECRET_ARN"
name="$TARGET_NAME"
namespace="$TARGET_NAMESPACE"
db_address="$DB_ADDRESS"
db_port="$DB_PORT"
db_name="$DB_NAME"

echo "[rds-secrets import] kubectl auth whoami"
echo "pwd: $(pwd)"
kubectl auth whoami -o json | jq -c

echo "[rds-secrets import] reading db access secrets from AWS Secrets Manager"
secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$secret_arn")
username=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
password=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

# URL-encode the password (special characters break connection string parsing)
encoded_password=$(printf '%s' "$password" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')

# Build connection URL in the format Coder expects
# postgres://username:password@hostname:port/database?sslmode=disable
connection_url="postgres://${username}:${encoded_password}@${db_address}:${db_port}/${db_name}?sslmode=disable"

echo "[rds-secrets import] creating namespace if not exists"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[rds-secrets import] creating RDS access secret"
kubectl create -n "$namespace" secret generic "$name" \
  --save-config    \
  --dry-run=client \
  --from-literal=username="$username" \
  --from-literal=password="$password" \
  --from-literal=url="$connection_url" \
  -o yaml | kubectl apply -f -

echo "[rds-secrets import] secret created successfully"

# Also create secret for observability namespace
observability_namespace="coder-observability"
observability_secret_name="coder-db-password"

echo "[rds-secrets import] creating observability namespace if not exists"
kubectl create namespace "$observability_namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[rds-secrets import] creating postgres password secret for observability"
kubectl create -n "$observability_namespace" secret generic "$observability_secret_name" \
  --save-config \
  --dry-run=client \
  --from-literal=PGPASSWORD="$password" \
  -o yaml | kubectl apply -f -

echo "[rds-secrets import] observability secret created successfully"

# Generate and store Grafana admin password
grafana_secret_name="grafana-admin-${INSTALL_ID}"
grafana_username="admin"

echo "[rds-secrets import] checking if Grafana admin secret exists in Secrets Manager"
if aws --region "$region" secretsmanager describe-secret --secret-id="$grafana_secret_name" 2>/dev/null; then
  echo "[rds-secrets import] Grafana admin secret already exists, retrieving"
  grafana_secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$grafana_secret_name")
  grafana_password=$(echo "$grafana_secret" | jq -r '.SecretString' | jq -r '.password')
else
  echo "[rds-secrets import] generating new Grafana admin password"
  grafana_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

  echo "[rds-secrets import] storing Grafana admin password in Secrets Manager"
  aws --region "$region" secretsmanager create-secret \
    --name "$grafana_secret_name" \
    --description "Grafana admin credentials for Nuon install ${INSTALL_ID}" \
    --secret-string "{\"username\":\"${grafana_username}\",\"password\":\"${grafana_password}\"}" \
    --tags Key=nuon-install-id,Value="${INSTALL_ID}" Key=component,Value=observability
fi

echo "[rds-secrets import] creating Grafana admin secret in Kubernetes"
kubectl create -n "$observability_namespace" secret generic grafana-admin \
  --save-config \
  --dry-run=client \
  --from-literal=username="$grafana_username" \
  --from-literal=password="$grafana_password" \
  -o yaml | kubectl apply -f -

echo "[rds-secrets import] Grafana admin secret created successfully"

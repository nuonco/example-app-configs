#!/usr/bin/env bash

set -e
set -o pipefail
set -u

region="$REGION"
db_address="$DB_ADDRESS"
db_port="$DB_PORT"
db_name="$DB_NAME"
master_username="$MASTER_USERNAME"
master_secret_arn="$MASTER_SECRET_ARN"
exporter_username="$EXPORTER_USERNAME"
namespace="$TARGET_NAMESPACE"
exporter_namespace="$EXPORTER_NAMESPACE"
exporter_secret_name="$EXPORTER_SECRET_NAME"
install_id="$INSTALL_ID"

echo "[coder-db-init] kubectl auth whoami"
kubectl auth whoami -o json | jq -c

# The throwaway psql pods run in the coder namespace, which may not exist
# yet the first time this fires (it triggers post-deploy of rds_cluster_coder,
# before the coder helm chart deploys).
echo "[coder-db-init] creating $namespace namespace if not exists"
kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

urlencode() {
  printf '%s' "$1" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))'
}

run_sql() {
  local conn_url="$1"
  local sql="$2"
  local pod
  pod="coder-db-init-$(date +%s)-$$"
  kubectl run "$pod" -n "$namespace" \
    --rm -i --restart=Never --quiet \
    --image=postgres:16-alpine --command -- \
    psql "$conn_url" -v ON_ERROR_STOP=1 -c "$sql"
}

# Self-healing admin connection: try an IAM token first (works once
# rds_iam has already been granted to the master user), and only fall
# back to the AWS-managed master password on the very first run, since
# granting rds_iam to a role disables password auth for that role.
echo "[coder-db-init] attempting IAM token connection as master ($master_username)"
iam_token=$(aws --region "$region" rds generate-db-auth-token \
  --hostname "$db_address" --port "$db_port" --username "$master_username")
iam_url="postgres://${master_username}:$(urlencode "$iam_token")@${db_address}:${db_port}/${db_name}?sslmode=require"

if run_sql "$iam_url" "SELECT 1;" >/tmp/coder-db-init-iam-check.log 2>&1; then
  echo "[coder-db-init] IAM token connection succeeded; rds_iam already granted to $master_username"
  admin_url="$iam_url"
else
  echo "[coder-db-init] IAM token connection failed, falling back to master password from Secrets Manager"
  secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$master_secret_arn")
  master_password=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')
  admin_url="postgres://${master_username}:$(urlencode "$master_password")@${db_address}:${db_port}/${db_name}?sslmode=require"
fi

# Reuse the exporter password across re-runs instead of rotating it every
# time this action fires, same idiom as grafana-setup/setup.sh.
exporter_secret_id="coder-exporter-${install_id}"
echo "[coder-db-init] checking if $exporter_username password already exists in Secrets Manager"
if aws --region "$region" secretsmanager describe-secret --secret-id="$exporter_secret_id" >/dev/null 2>&1; then
  echo "[coder-db-init] $exporter_username password already exists, retrieving"
  exporter_secret=$(aws --region "$region" secretsmanager get-secret-value --secret-id="$exporter_secret_id")
  exporter_password=$(echo "$exporter_secret" | jq -r '.SecretString' | jq -r '.password')
else
  echo "[coder-db-init] generating new $exporter_username password"
  exporter_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

  echo "[coder-db-init] storing $exporter_username password in Secrets Manager"
  aws --region "$region" secretsmanager create-secret \
    --name "$exporter_secret_id" \
    --description "Coder postgres-exporter credentials for Nuon install ${install_id}" \
    --secret-string "{\"username\":\"${exporter_username}\",\"password\":\"${exporter_password}\"}" \
    --tags Key=nuon-install-id,Value="${install_id}" Key=component,Value=coder-db
fi

echo "[coder-db-init] ensuring $exporter_username role exists with the current password"
run_sql "$admin_url" "
DO \$do\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${exporter_username}') THEN
    CREATE ROLE ${exporter_username} WITH LOGIN PASSWORD '${exporter_password}';
  ELSE
    ALTER ROLE ${exporter_username} WITH PASSWORD '${exporter_password}';
  END IF;
END
\$do\$;
"

echo "[coder-db-init] granting $exporter_username read-only access for metrics/dashboards"
run_sql "$admin_url" "GRANT CONNECT ON DATABASE ${db_name} TO ${exporter_username};"
run_sql "$admin_url" "GRANT pg_monitor TO ${exporter_username};"
run_sql "$admin_url" "GRANT USAGE ON SCHEMA public TO ${exporter_username};"
run_sql "$admin_url" "GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${exporter_username};"
run_sql "$admin_url" "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${exporter_username};"

# Must run last: this disables password auth for $master_username, which is
# why the admin connection above tries an IAM token before falling back.
echo "[coder-db-init] granting rds_iam to master user $master_username"
run_sql "$admin_url" "GRANT rds_iam TO ${master_username};"

echo "[coder-db-init] creating $exporter_namespace namespace if not exists"
kubectl create namespace "$exporter_namespace" --dry-run=client -o yaml | kubectl apply -f -

echo "[coder-db-init] writing $exporter_secret_name secret in $exporter_namespace"
kubectl create -n "$exporter_namespace" secret generic "$exporter_secret_name" \
  --save-config \
  --dry-run=client \
  --from-literal=PGPASSWORD="$exporter_password" \
  -o yaml | kubectl apply -f -

echo "[coder-db-init] done"

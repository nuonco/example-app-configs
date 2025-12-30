#!/usr/bin/env bash

set -e
set -o pipefail
set -u

echo "Stopping database activity simulation..."

# Get credentials from Secrets Manager
echo "[db-activity] Reading credentials from AWS Secrets Manager"
secret=$(aws --region "$REGION" secretsmanager get-secret-value --secret-id="$SECRET_ARN")
DB_USER=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
DB_PASS=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

# Use exampledb namespace
NAMESPACE="exampledb"

# Kill any running simulation pods
echo "[db-activity] Removing any simulation pods..."
kubectl delete pod -n "$NAMESPACE" -l run=db-activity-sim --ignore-not-found=true 2>/dev/null || true

# Also delete any pods matching the simulation pattern
for pod in $(kubectl get pods -n "$NAMESPACE" -o name 2>/dev/null | grep "db-activity-sim" || true); do
    kubectl delete "$pod" -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
done

# Create a temporary pod to terminate long-running queries
POD_NAME="db-stop-$(date +%s)"

echo "[db-activity] Creating temporary postgres client pod..."
kubectl run "$POD_NAME" \
  --namespace="$NAMESPACE" \
  --image=postgres:15-alpine \
  --restart=Never \
  --env="PGPASSWORD=$DB_PASS" \
  --env="PGHOST=$DB_HOST" \
  --env="PGPORT=$DB_PORT" \
  --env="PGUSER=$DB_USER" \
  --env="PGDATABASE=$DB_NAME" \
  --command -- sleep 60

echo "[db-activity] Waiting for pod to be ready..."
kubectl wait --namespace="$NAMESPACE" --for=condition=Ready pod/"$POD_NAME" --timeout=60s || true

# Terminate long-running queries
echo "[db-activity] Terminating long-running queries..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- psql -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'active' 
AND query_start < NOW() - interval '30 seconds'
AND query NOT LIKE '%pg_stat_activity%'
AND query NOT LIKE '%pg_terminate_backend%';
" 2>/dev/null || true

# Cleanup
echo "[db-activity] Cleaning up..."
kubectl delete pod "$POD_NAME" --namespace="$NAMESPACE" --ignore-not-found=true

echo "✅ STOP COMPLETE"
echo "Database should return to normal activity levels within 60 seconds."

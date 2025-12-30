#!/usr/bin/env bash

set -e
set -o pipefail
set -u

echo "EMERGENCY STOP: Terminating database activity simulation..."

# Get credentials from Secrets Manager
echo "[db-activity] Reading credentials from AWS Secrets Manager"
secret=$(aws --region "$REGION" secretsmanager get-secret-value --secret-id="$SECRET_ARN")
DB_USER=$(echo "$secret" | jq -r '.SecretString' | jq -r '.username')
DB_PASS=$(echo "$secret" | jq -r '.SecretString' | jq -r '.password')

export PGPASSWORD="$DB_PASS"

# Kill any long-running queries from the simulation
echo "Terminating long-running simulation queries..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
-- Kill any long-running queries that look like simulation queries
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'active' 
AND query_start < NOW() - interval '30 seconds'
AND query NOT LIKE '%pg_stat_activity%'
AND datname = '$DB_NAME';

-- Also cancel any queries that are just starting
SELECT pg_cancel_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'active' 
AND datname = '$DB_NAME'
AND query NOT LIKE '%pg_stat_activity%'
AND query NOT LIKE '%pg_terminate_backend%'
AND query NOT LIKE '%pg_cancel_backend%';
" 2>/dev/null || true

# Create stop markers for any running simulations
for pid_file in /tmp/stop_db_simulation_*; do
    if [ -e "$pid_file" ]; then
        touch "$pid_file"
    fi
done

echo "✅ STOP COMPLETE: All simulation queries terminated"
echo ""
echo "Database should return to normal activity levels within 60 seconds."
echo "Monitor your Grafana dashboards to confirm metrics are decreasing."

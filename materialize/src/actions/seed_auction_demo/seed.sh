#!/usr/bin/env bash

set -euo pipefail

namespace="$TARGET_NAMESPACE"
backend_secret="$BACKEND_SECRET"
sql_host="$SQL_HOST"
sql_port="$SQL_PORT"
sql_user="$SQL_USER"
sql_database="$SQL_DATABASE"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sql_file="${script_dir}/auction.sql"

echo "[seed-auction] kubectl auth whoami"
kubectl auth whoami -o json | jq -c

echo "[seed-auction] waiting for backend secret ${backend_secret}"
for i in $(seq 1 60); do
  if kubectl -n "$namespace" get secret "$backend_secret" >/dev/null 2>&1; then
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "[seed-auction] secret ${backend_secret} not found; run backend_secret first" >&2
    exit 1
  fi
  sleep 5
done

password=$(kubectl -n "$namespace" get secret "$backend_secret" -o jsonpath='{.data.external_login_password_mz_system}' | base64 -d)
if [[ -z "$password" ]]; then
  echo "[seed-auction] mz_system password missing in ${backend_secret}" >&2
  exit 1
fi

encoded_password=$(printf '%s' "$password" | python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=""))')
conn_url="postgres://${sql_user}:${encoded_password}@${sql_host}:${sql_port}/${sql_database}?sslmode=prefer"

run_psql() {
  local args=("$@")
  local pod
  pod="mz-seed-$(date +%s)-$$"
  kubectl run "$pod" -n "$namespace" \
    --rm -i --restart=Never --quiet \
    --image=postgres:16-alpine --command -- \
    psql "$conn_url" -v ON_ERROR_STOP=1 "${args[@]}"
}

echo "[seed-auction] waiting for mz-sql endpoints"
for i in $(seq 1 60); do
  addrs=$(kubectl -n "$namespace" get endpoints mz-sql -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
  if [[ -n "$addrs" ]]; then
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "[seed-auction] timed out waiting for mz-sql endpoints" >&2
    exit 1
  fi
  sleep 5
done

echo "[seed-auction] waiting for SQL accept"
ready=0
for i in $(seq 1 36); do
  if run_psql -c "SELECT 1;" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 5
done
if [[ "$ready" -ne 1 ]]; then
  echo "[seed-auction] timed out waiting for Materialize SQL" >&2
  exit 1
fi

exists=$(run_psql -Atc "SELECT count(*)::text FROM mz_sources WHERE name = 'auction_house';" | tr -d '[:space:]')
if [[ "$exists" != "0" ]]; then
  echo "[seed-auction] auction_house source already present; skipping create"
else
  echo "[seed-auction] applying auction.sql"
  run_psql -f - <"$sql_file"
fi

echo "[seed-auction] sample auctions"
run_psql -c "SELECT id, seller, item, end_time FROM auctions LIMIT 3;" || true

echo "[seed-auction] done"
echo "Console: ${CONSOLE_URL}"
echo "Try: SELECT * FROM winning_bids ORDER BY bid_time DESC LIMIT 10;"

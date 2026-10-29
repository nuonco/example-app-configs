#!/usr/bin/env bash

set -euo pipefail

namespace="$TARGET_NAMESPACE"
name="$TARGET_NAME"

if ! kubectl -n "$namespace" get secret "$name" >/dev/null 2>&1; then
  echo "Secret ${namespace}/${name} not found. Run the backend_secret action first." >&2
  exit 1
fi

password=$(kubectl -n "$namespace" get secret "$name" -o jsonpath='{.data.external_login_password_mz_system}' | base64 -d)

echo "Console URL: ${CONSOLE_URL}"
echo "SQL host:    ${SQL_HOST}:6875"
echo "User:        mz_system"
echo "Password:    ${password}"
echo ""
echo "psql \"postgres://mz_system@${SQL_HOST}:6875/materialize\""

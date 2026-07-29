#!/usr/bin/env bash
set -euo pipefail

for command in curl jq; do
  command -v "$command" >/dev/null || { echo "$command is required" >&2; exit 1; }
done

app_dir=$(cd "$(dirname "$0")/.." && pwd)
if [[ -f "$app_dir/.demo.env" ]]; then
  # shellcheck disable=SC1091
  source "$app_dir/.demo.env"
fi

: "${BRANCH_INGRESS_URL:?Run scripts/1-setup-triggers.sh or set BRANCH_INGRESS_URL}"
: "${BRANCH_TRIGGER_SECRET:?Run scripts/1-setup-triggers.sh or set BRANCH_TRIGGER_SECRET}"

event_id="app-branch-run-$(date -u +%s)-${RANDOM}"
body=$(jq -nc --arg source "${1:-operator}" '{source:$source}')

curl --fail-with-body --request POST \
  --url "$BRANCH_INGRESS_URL" \
  --header 'Content-Type: application/json' \
  --header "X-Nuon-API-Key: $BRANCH_TRIGGER_SECRET" \
  --header 'X-Nuon-Event-Type: app.branch.run' \
  --header "X-Nuon-Event-ID: $event_id" \
  --data "$body"

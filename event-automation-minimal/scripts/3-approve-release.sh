#!/usr/bin/env bash
set -euo pipefail

app_dir=$(cd "$(dirname "$0")/.." && pwd)
if [[ -f "$app_dir/.demo.env" ]]; then
  # shellcheck disable=SC1091
  source "$app_dir/.demo.env"
fi

: "${APPROVAL_INGRESS_URL:?Run scripts/1-setup-triggers.sh or set APPROVAL_INGRESS_URL}"
: "${APPROVAL_TRIGGER_SECRET:?Run scripts/1-setup-triggers.sh or set APPROVAL_TRIGGER_SECRET}"
: "${1:?Usage: scripts/3-approve-release.sh <full-gar-image-tag> [approved-by]}"

full_tag=$1
approved_by=${2:-$(whoami)}
event_id="release-approval-$(date -u +%s)-${RANDOM}"
body=$(jq -nc --arg tag "$full_tag" --arg approved_by "$approved_by" '{tag:$tag, approved_by:$approved_by}')

curl --fail-with-body --request POST \
  --url "$APPROVAL_INGRESS_URL" \
  --header 'Content-Type: application/json' \
  --header "X-Nuon-API-Key: $APPROVAL_TRIGGER_SECRET" \
  --header 'X-Nuon-Event-Type: release.approved' \
  --header "X-Nuon-Event-ID: $event_id" \
  --data "$body"

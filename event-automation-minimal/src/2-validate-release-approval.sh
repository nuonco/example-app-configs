#!/usr/bin/env sh
set -eu

TRIGGER_TAG='{{.runbook_inputs.image_tag}}'
APPROVED_TAG='{{(index .runbook_outputs "wait-for-release-approval").event.payload.tag}}'
APPROVED_BY='{{(index .runbook_outputs "wait-for-release-approval").event.payload.approved_by}}'

[ "$TRIGGER_TAG" = "$APPROVED_TAG" ] || { echo "Approval tag mismatch"; exit 1; }
echo "Release approved by $APPROVED_BY for $APPROVED_TAG"
printf '{"tag":"%s","approved_by":"%s"}\n' "$APPROVED_TAG" "$APPROVED_BY" >> "$NUON_ACTIONS_OUTPUT_FILEPATH"

#!/usr/bin/env sh
set -eu

FULL_TAG='{{.runbook_inputs.image_tag}}'
case "$FULL_TAG" in
  us-west1-docker.pkg.dev/nuon-gcp-support/nuon-event-proof/clickhouse-server:*) ;;
  *) echo "Unexpected GAR image reference: $FULL_TAG"; exit 1 ;;
esac

echo "Validated triggering GAR tag: $FULL_TAG"

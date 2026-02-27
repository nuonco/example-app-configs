#!/usr/bin/env sh

# given a BUCKET_NAME, empty the bucket of all of its contents. this action is intended
# to run during deprovision before the sandbox is torn down. the bucket itself is part of
# of the custom stack so we delete the content here before the stack is deleted by the
# customer in the cloudformation UI.

set -e
set -o pipefail
set -u

bucket="$BUCKET_NAME"
deleted_versioned_entries=0
batches_processed=0

emit_output() {
  state="$1"
  if [ -n "${NUON_ACTIONS_OUTPUT_FILEPATH:-}" ]; then
    jq -cn \
      --arg state "$state" \
      --arg bucket "$bucket" \
      --argjson deleted_versioned_entries "$deleted_versioned_entries" \
      --argjson batches_processed "$batches_processed" \
      '{state: $state, bucket: $bucket, deleted_versioned_entries: $deleted_versioned_entries, batches_processed: $batches_processed}' \
      > "$NUON_ACTIONS_OUTPUT_FILEPATH"
  fi
}

AWS_PAGER=""

if ! aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "bucket $bucket not found or not accessible; skipping"
  emit_output "skipped"
  exit 0
fi

echo "emptying current objects from s3://$bucket"
aws s3 rm "s3://$bucket" --recursive || true

echo "emptying versioned objects and delete markers from s3://$bucket"
key_marker=""
version_id_marker=""

while :; do
  if [ -n "$key_marker" ]; then
    versions_json=$(aws s3api list-object-versions \
      --bucket "$bucket" \
      --key-marker "$key_marker" \
      --version-id-marker "$version_id_marker")
  else
    versions_json=$(aws s3api list-object-versions --bucket "$bucket")
  fi

  delete_payload=$(echo "$versions_json" | jq -c '{Objects: ((.Versions // []) + (.DeleteMarkers // []) | map({Key: .Key, VersionId: .VersionId})), Quiet: true}')
  object_count=$(echo "$delete_payload" | jq '.Objects | length')

  if [ "$object_count" -gt 0 ]; then
    aws s3api delete-objects --bucket "$bucket" --delete "$delete_payload" >/dev/null
    echo "deleted $object_count versioned entries"
    deleted_versioned_entries=$((deleted_versioned_entries + object_count))
  fi

  batches_processed=$((batches_processed + 1))

  is_truncated=$(echo "$versions_json" | jq -r '.IsTruncated // false')
  if [ "$is_truncated" != "true" ]; then
    break
  fi

  key_marker=$(echo "$versions_json" | jq -r '.NextKeyMarker // ""')
  version_id_marker=$(echo "$versions_json" | jq -r '.NextVersionIdMarker // ""')
done

echo "bucket s3://$bucket is empty"
emit_output "emptied"

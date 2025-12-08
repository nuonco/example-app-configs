#!/bin/bash
set -e
set -o pipefail
set -u

ROLE_NAME="AWSServiceRoleForECS"

existing_role=$(aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null || echo "")

if [[ -z "$existing_role" ]]; then
  role=$(aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com)
else
  role="$existing_role"
fi

echo "$role" | jq -c '.Role' > "$NUON_ACTIONS_OUTPUT_FILEPATH"

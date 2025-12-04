#!/usr/bin/env bash

set -o pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <VENDOR_ROLE_ARN>

Drop into a shell with AWS credentials for the vendor role.

This script assumes the specified vendor role and spawns a subshell
with the temporary credentials exported, allowing access to resources
granted by the role delegation component.

Arguments:
  VENDOR_ROLE_ARN    ARN of the vendor IAM role to assume

Options:
  -s, --session      Session name for the assumed role (default: vendor-shell)
  -h, --help         Show this help message and exit

Examples:
  $(basename "$0") arn:aws:iam::123456789012:role/nuon-vendor-role
  $(basename "$0") -s my-session arn:aws:iam::123456789012:role/nuon-vendor-role
EOF
  exit 0
}

SESSION_NAME="vendor-shell"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -s|--session)
      SESSION_NAME="$2"
      shift 2
      ;;
    *)
      VENDOR_ROLE_ARN="$1"
      shift
      ;;
  esac
done

if [ -z "$VENDOR_ROLE_ARN" ]; then
  echo >&2 "error: VENDOR_ROLE_ARN is required"
  echo >&2 ""
  usage
fi

set -e
export AWS_PAGER=""

echo >&2 "assuming $VENDOR_ROLE_ARN"
resp=$(aws sts assume-role \
    --role-arn "$VENDOR_ROLE_ARN" \
    --role-session-name="$SESSION_NAME")

export AWS_ACCESS_KEY_ID=$(echo "$resp" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$resp" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$resp" | jq -r .Credentials.SessionToken)

echo >&2 "successfully assumed $VENDOR_ROLE_ARN"
aws sts get-caller-identity

echo >&2 "creating subshell"
echo >&2 " - exit [ctrl-D] to return to original session"

# exec "${SHELL:-sh}"
exec bash --init-file <(echo 'PS1="[\033[36mvendor-role\033[0m] \033[32m$\033[0m "')

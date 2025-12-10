#!/usr/bin/env bash

set -o pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <VENDOR_ROLE_ARN> <INSTALL_ROLE_ARN>

Drop into a shell with AWS credentials for the install role via the vendor role.

This script first assumes the vendor role, then uses those credentials to
assume the install role, and spawns a subshell with the final credentials.

Arguments:
  VENDOR_ROLE_ARN    ARN of the vendor IAM role to assume first
  INSTALL_ROLE_ARN   ARN of the install IAM role to assume via vendor role

Options:
  -s, --session      Session name for the assumed roles (default: install-shell)
  -h, --help         Show this help message and exit

Examples:
  $(basename "$0") arn:aws:iam::111111111111:role/nuon-vendor-role arn:aws:iam::222222222222:role/nuon-delegated-role
EOF
  exit 0
}

AWS_PAGER=""
SESSION_NAME="install-shell"

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
      if [ -z "${VENDOR_ROLE_ARN:-}" ]; then
        VENDOR_ROLE_ARN="$1"
      elif [ -z "${INSTALL_ROLE_ARN:-}" ]; then
        INSTALL_ROLE_ARN="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "${VENDOR_ROLE_ARN:-}" ] || [ -z "${INSTALL_ROLE_ARN:-}" ]; then
  echo >&2 "error: VENDOR_ROLE_ARN and INSTALL_ROLE_ARN are required"
  echo >&2 ""
  usage
fi

set -e
export AWS_PAGER=""

echo >&2 "assuming vendor role: $VENDOR_ROLE_ARN"
vendor_resp=$(aws sts assume-role \
    --role-arn "$VENDOR_ROLE_ARN" \
    --role-session-name="${SESSION_NAME}-vendor")

export AWS_ACCESS_KEY_ID=$(echo "$vendor_resp" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$vendor_resp" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$vendor_resp" | jq -r .Credentials.SessionToken)

echo >&2 "successfully assumed vendor role"
aws sts get-caller-identity

echo >&2 "assuming install role: $INSTALL_ROLE_ARN"
install_resp=$(aws sts assume-role \
    --role-arn "$INSTALL_ROLE_ARN" \
    --role-session-name="${SESSION_NAME}")

export AWS_ACCESS_KEY_ID=$(echo "$install_resp" | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo "$install_resp" | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo "$install_resp" | jq -r .Credentials.SessionToken)

echo >&2 "successfully assumed install role"
aws sts get-caller-identity

echo >&2 "creating subshell"
echo >&2 " - exit [ctrl-D] to return to original session"

# exec "${SHELL:-sh}"
exec bash --init-file <(echo 'PS1="[\033[35minstall-role\033[0m] \033[31m$\033[0m "')

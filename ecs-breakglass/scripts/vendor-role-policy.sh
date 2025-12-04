#!/usr/bin/env bash

set -e
set -o pipefail
set -u

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] VENDOR_ROLE_ARN INSTALL_ROLE_ARN

Attach an inline policy to the vendor role allowing it to assume the install role.

Arguments:
  VENDOR_ROLE_ARN   ARN of the vendor role to attach the policy to
  INSTALL_ROLE_ARN  ARN of the install role the vendor can assume

Options:
  -h, --help        Show this help message and exit

Examples:
  $(basename "$0") arn:aws:iam::111111111111:role/nuon-vendor-role arn:aws:iam::222222222222:role/nuon-delegated-role
EOF
  exit 0
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && usage

if [[ $# -lt 2 ]]; then
  echo "Error: Both VENDOR_ROLE_ARN and INSTALL_ROLE_ARN are required" >&2
  echo "Run '$(basename "$0") --help' for usage" >&2
  exit 1
fi

AWS_PAGER=""
VENDOR_ROLE_ARN="$1"
INSTALL_ROLE_ARN="$2"

VENDOR_ROLE_NAME=$(echo "$VENDOR_ROLE_ARN" | sed 's|.*/||')

POLICY_NAME="assume-install-role-$(echo "$INSTALL_ROLE_ARN" | sed 's|.*/||')"

POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${INSTALL_ROLE_ARN}"
    }
  ]
}
EOF
)

echo "Attaching policy to vendor role: $VENDOR_ROLE_NAME"
echo "Policy name: $POLICY_NAME"
echo "Allows assuming: $INSTALL_ROLE_ARN"

aws iam put-role-policy \
  --role-name "$VENDOR_ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document "$POLICY_DOCUMENT"

echo ""
echo "Policy attached successfully!"
echo ""
echo "The vendor role can now assume the install role with:"
echo "  aws sts assume-role --role-arn $INSTALL_ROLE_ARN --role-session-name vendor-access"

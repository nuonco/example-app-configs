#!/usr/bin/env bash

set -e
set -o pipefail
set -u

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [ROLE_NAME]

! For demonstration purposes only !

Create an IAM role for use as the vendor_role in role delegation.

This would be provided to the customer during install so they can (optionally?)
grant the vendor access to the install; e.g. via the AWS CLI.

Arguments:
  ROLE_NAME    Name for the vendor role (default: ecs-breakglass-vendor-role)

Options:
  -h, --help   Show this help message and exit

Environment Variables:
  AWS_REGION   AWS region (default: us-west-2)

Examples:
  $(basename "$0")
  $(basename "$0") my-vendor-role
  AWS_REGION=us-east-1 $(basename "$0") my-vendor-role
EOF
  exit 0
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && usage

AWS_PAGER=""
ROLE_NAME="${1:-ecs-breakglass-vendor-role}"
REGION="${AWS_REGION:-us-west-2}"

echo "Creating vendor role: $ROLE_NAME"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "$TRUST_POLICY" \
  --description "Vendor role for cross-account access delegation" \
  --tags Key=Purpose,Value=ecs-breakglass-vendor-delegation

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

echo ""
echo "Vendor role created successfully!"
echo "Role ARN: $ROLE_ARN"
echo ""
echo "Use this ARN as the 'vendor_role_arn' input for your Nuon install."

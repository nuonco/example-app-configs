#!/usr/bin/env bash

set -e
set -o pipefail
set -u

: "${AWS_PROFILE:?set AWS_PROFILE to the install account profile}"
export AWS_PAGER=""

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stack_dir="$script_dir/../install-stack"
tfvars="$stack_dir/install.auto.tfvars"

install_id="$(sed -n 's/^nuon_install_id[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$tfvars")"
region="$(sed -n 's/^aws_region[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$tfvars")"
cluster_name="$(sed -n 's/.*"cluster_name"[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$tfvars")"
if [[ -z "$install_id" || -z "$region" ]]; then
  printf 'error: %s is missing nuon_install_id or aws_region\n' "$tfvars" >&2
  exit 1
fi

role_name="${install_id}-tf-apply"
account_id="$(aws sts get-caller-identity --query Account --output text)"
caller_arn="$(aws sts get-caller-identity --query Arn --output text)"
case "$caller_arn" in
*:assumed-role/*)
  caller_role_name="${caller_arn#*:assumed-role/}"
  caller_role_name="${caller_role_name%%/*}"
  principal_arn="$(aws iam get-role --role-name "$caller_role_name" --query Role.Arn --output text)"
  ;;
*:user/*)
  principal_arn="$caller_arn"
  ;;
*)
  printf 'error: unsupported caller %s\n' "$caller_arn" >&2
  exit 1
  ;;
esac

trust_file="$(mktemp)"
policy_file="$(mktemp)"
cleanup() {
  rm -f "$trust_file" "$policy_file"
}
trap cleanup EXIT

jq -n --arg principal "$principal_arn" '{
  Version: "2012-10-17",
  Statement: [{
    Effect: "Allow",
    Principal: {AWS: $principal},
    Action: ["sts:AssumeRole", "sts:TagSession"]
  }]
}' >"$trust_file"

cluster_arn="*"
if [[ -n "$cluster_name" ]]; then
  cluster_arn="arn:aws:eks:${region}:${account_id}:cluster/${cluster_name}"
fi

jq -n \
  --arg account "$account_id" \
  --arg region "$region" \
  --arg prefix "$install_id" \
  --arg cluster "$cluster_arn" \
  '{
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "Read",
        Effect: "Allow",
        Action: [
          "ec2:Describe*",
          "autoscaling:Describe*",
          "eks:Describe*",
          "eks:List*",
          "logs:Describe*",
          "logs:ListTagsForResource",
          "logs:ListTagsLogGroup",
          "iam:Get*",
          "iam:List*"
        ],
        Resource: "*"
      },
      {
        Sid: "NetworkAndCompute",
        Effect: "Allow",
        Action: [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:ModifySecurityGroupRules",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteLaunchTemplateVersions",
          "ec2:ModifyLaunchTemplate",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:StartInstanceRefresh",
          "autoscaling:CancelInstanceRefresh",
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:TagLogGroup",
          "logs:UntagLogGroup"
        ],
        Resource: "*"
      },
      {
        Sid: "Iam",
        Effect: "Allow",
        Action: [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePermissionsBoundary",
          "iam:DeleteRolePermissionsBoundary",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:CreateServiceLinkedRole"
        ],
        Resource: [
          ("arn:aws:iam::" + $account + ":role/*"),
          ("arn:aws:iam::" + $account + ":role/aws-service-role/*"),
          ("arn:aws:iam::" + $account + ":instance-profile/" + $prefix + "-*"),
          ("arn:aws:iam::" + $account + ":policy/" + $prefix + "-*")
        ]
      },
      {
        Sid: "PassRoles",
        Effect: "Allow",
        Action: "iam:PassRole",
        Resource: ("arn:aws:iam::" + $account + ":role/" + $prefix + "-*"),
        Condition: {
          StringEquals: {
            "iam:PassedToService": [
              "ec2.amazonaws.com",
              "autoscaling.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid: "EksAccess",
        Effect: "Allow",
        Action: [
          "eks:DescribeCluster",
          "eks:AccessKubernetesApi",
          "eks:CreateAccessEntry",
          "eks:DeleteAccessEntry",
          "eks:UpdateAccessEntry",
          "eks:AssociateAccessPolicy",
          "eks:DisassociateAccessPolicy",
          "eks:TagResource",
          "eks:UntagResource"
        ],
        Resource: $cluster
      }
    ]
  }' >"$policy_file"

if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
  printf 'updating %s\n' "$role_name" >&2
  aws iam update-assume-role-policy \
    --role-name "$role_name" \
    --policy-document "file://${trust_file}"
else
  printf 'creating %s\n' "$role_name" >&2
  aws iam create-role \
    --role-name "$role_name" \
    --assume-role-policy-document "file://${trust_file}" \
    --description "Applies the Nuon install stack for ${install_id}"
fi
aws iam put-role-policy \
  --role-name "$role_name" \
  --policy-name tf-apply \
  --policy-document "file://${policy_file}"

role_arn="$(aws iam get-role --role-name "$role_name" --query Role.Arn --output text)"

if [[ -n "$cluster_name" ]]; then
  if ! aws eks describe-access-entry \
    --region "$region" \
    --cluster-name "$cluster_name" \
    --principal-arn "$role_arn" >/dev/null 2>&1; then
    printf 'adding access entry for %s\n' "$role_arn" >&2
    created=0
    for _ in $(seq 1 12); do
      if aws eks create-access-entry \
        --region "$region" \
        --cluster-name "$cluster_name" \
        --principal-arn "$role_arn" \
        --type STANDARD \
        --username tf-apply; then
        created=1
        break
      fi
      printf 'waiting for %s to propagate\n' "$role_arn" >&2
      sleep 5
    done
    if [[ "$created" != 1 ]]; then
      printf 'error: create-access-entry for %s failed\n' "$role_arn" >&2
      exit 1
    fi
  fi

  admin_policy="arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  associated="$(aws eks list-associated-access-policies \
    --region "$region" \
    --cluster-name "$cluster_name" \
    --principal-arn "$role_arn" \
    --query "associatedAccessPolicies[?policyArn=='${admin_policy}'].policyArn" \
    --output text)"
  if [[ -z "$associated" || "$associated" == "None" ]]; then
    printf 'associating cluster admin on %s\n' "$cluster_name" >&2
    aws eks associate-access-policy \
      --region "$region" \
      --cluster-name "$cluster_name" \
      --principal-arn "$role_arn" \
      --access-scope type=cluster \
      --policy-arn "$admin_policy"
  fi
fi

printf 'assuming %s\n' "$role_arn" >&2
resp=""
for _ in $(seq 1 12); do
  if resp="$(aws sts assume-role \
    --role-arn "$role_arn" \
    --role-session-name tf-apply)"; then
    break
  fi
  sleep 5
done
if [[ -z "$resp" ]]; then
  printf 'error: assume-role %s failed\n' "$role_arn" >&2
  exit 1
fi

access_key_id="$(jq -er '.Credentials.AccessKeyId' <<<"$resp")"
secret_access_key="$(jq -er '.Credentials.SecretAccessKey' <<<"$resp")"
session_token="$(jq -er '.Credentials.SessionToken' <<<"$resp")"

(
  unset AWS_PROFILE
  export AWS_ACCESS_KEY_ID="$access_key_id"
  export AWS_SECRET_ACCESS_KEY="$secret_access_key"
  export AWS_SESSION_TOKEN="$session_token"
  export AWS_REGION="$region"
  export AWS_DEFAULT_REGION="$region"
  terraform -chdir="$stack_dir" init -input=false
  terraform -chdir="$stack_dir" apply -input=false "$@"
)

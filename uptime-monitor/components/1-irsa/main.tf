# -----------------------------------------------------------------------------
# IRSA (IAM Roles for Service Accounts) for Uptime Monitor
# -----------------------------------------------------------------------------
#
# Variables are passed from the Nuon component config (1-irsa.toml):
#   - var.region                <- {{.nuon.install_stack.outputs.region}}
#   - var.install_id            <- {{.nuon.install.id}}
#   - var.cluster_oidc_provider <- {{.nuon.install.sandbox.outputs.cluster.oidc_provider}}
#   - var.s3_bucket_arn         <- {{.nuon.components.s3.outputs.bucket_arn}}
#
# Outputs are available to other components via:
#   {{.nuon.components.irsa.outputs.role_arn}}
#
# This role is referenced in the API manifest's ServiceAccount annotation.
#
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Nuon tagging convention for resource tracking
  default_tags {
    tags = {
      "install.nuon.co/id"     = var.install_id
      "component.nuon.co/name" = "irsa"
    }
  }
}

# Variables passed from Nuon component config
variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

# From sandbox outputs: {{.nuon.install.sandbox.outputs.cluster.oidc_provider}}
variable "cluster_oidc_provider" {
  type        = string
  description = "EKS cluster OIDC provider for IRSA"
}

# From s3 component outputs: {{.nuon.components.s3.outputs.bucket_arn}}
variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket to grant access to"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

# IAM policy for S3 bucket access
data "aws_iam_policy_document" "s3_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.s3_bucket_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${var.s3_bucket_arn}/*"]
  }
}

# IAM policy for RDS access (drift detection demo)
data "aws_iam_policy_document" "rds_access" {
  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:ModifyDBInstance",
      "rds:AddTagsToResource"
    ]
    resources = ["arn:aws:rds:${var.region}:${local.account_id}:db:*"]
  }
}

# Trust policy for IRSA
data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/${var.cluster_oidc_provider}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.cluster_oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.cluster_oidc_provider}:sub"
      values   = ["system:serviceaccount:default:api"]
    }
  }
}

# IAM role for the API service account
resource "aws_iam_role" "api" {
  name               = "${var.install_id}-uptime-api-role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json

  inline_policy {
    name   = "s3-access"
    policy = data.aws_iam_policy_document.s3_access.json
  }

  inline_policy {
    name   = "rds-access"
    policy = data.aws_iam_policy_document.rds_access.json
  }
}

# Outputs - referenced by other Nuon components
output "role_arn" {
  value       = aws_iam_role.api.arn
  description = "IAM role ARN for the API service account"
}

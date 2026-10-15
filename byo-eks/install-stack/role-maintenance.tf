data "aws_iam_policy_document" "maintenance" {
  statement {
    sid = "Ec2NetworkRead"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(local.maintenance_eks_read_resources) > 0 ? [1] : []
    content {
      sid = "ReadSelectedCluster"
      actions = [
        "eks:DescribeCluster",
        "eks:AccessKubernetesApi",
        "eks:ListNodegroups",
        "eks:DescribeNodegroup",
        "eks:ListAddons",
        "eks:DescribeAddon",
        "eks:ListUpdates",
        "eks:DescribeUpdate",
        "eks:ListAccessEntries",
        "eks:DescribeAccessEntry",
        "eks:ListAssociatedAccessPolicies",
      ]
      resources = local.maintenance_eks_read_resources
    }
  }

  statement {
    sid       = "ListOpenIDConnectProviders"
    actions   = ["iam:ListOpenIDConnectProviders"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = local.maintenance_oidc_provider_arn == null ? [] : [local.maintenance_oidc_provider_arn]
    content {
      sid = "ReadClusterOidcProvider"
      actions = [
        "iam:GetOpenIDConnectProvider",
        "iam:ListOpenIDConnectProviderTags",
      ]
      resources = [statement.value]
    }
  }

  statement {
    sid = "ReadInstallRoles"
    actions = [
      "iam:GetRole",
      "iam:ListRoleTags",
      "iam:ListAttachedRolePolicies",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-*"]
  }

  statement {
    sid       = "EcrAuthorizationToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ManageInstallRepository"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:UploadLayerPart",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.prefix}"]
  }

  statement {
    sid = "UseEcrKmsKey"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ecr.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid = "GrantEcrKmsKey"
    actions = [
      "kms:CreateGrant",
      "kms:RetireGrant",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ecr.${var.aws_region}.amazonaws.com"]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid = "ManageEcrAccessPolicy"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/ecr-access-${local.prefix}"]
  }

  statement {
    sid = "AttachEcrAccessPolicy"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-*"]
  }
}

data "aws_iam_policy_document" "maintenance_boundary" {
  statement {
    sid = "ScopedReads"
    actions = [
      "sts:GetCallerIdentity",
      "sts:GetServiceBearerToken",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(local.maintenance_eks_read_resources) > 0 ? [1] : []
    content {
      sid = "EksReadSelectedClusterOnly"
      actions = [
        "eks:DescribeCluster",
        "eks:AccessKubernetesApi",
        "eks:ListNodegroups",
        "eks:DescribeNodegroup",
        "eks:ListAddons",
        "eks:DescribeAddon",
        "eks:ListUpdates",
        "eks:DescribeUpdate",
        "eks:ListAccessEntries",
        "eks:DescribeAccessEntry",
        "eks:ListAssociatedAccessPolicies",
      ]
      resources = local.maintenance_eks_read_resources
    }
  }

  statement {
    sid       = "ListOpenIDConnectProviders"
    actions   = ["iam:ListOpenIDConnectProviders"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = local.maintenance_oidc_provider_arn == null ? [] : [local.maintenance_oidc_provider_arn]
    content {
      sid = "ReadClusterOidcProvider"
      actions = [
        "iam:GetOpenIDConnectProvider",
        "iam:ListOpenIDConnectProviderTags",
      ]
      resources = [statement.value]
    }
  }

  statement {
    sid = "IamReadInstallRolesOnly"
    actions = [
      "iam:GetRole",
      "iam:ListRoleTags",
      "iam:ListAttachedRolePolicies",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-*"]
  }

  statement {
    sid       = "EcrAuthorizationToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ManageInstallRepository"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:UploadLayerPart",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.prefix}"]
  }

  statement {
    sid = "UseEcrKmsKey"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ecr.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid = "GrantEcrKmsKey"
    actions = [
      "kms:CreateGrant",
      "kms:RetireGrant",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ecr.${var.aws_region}.amazonaws.com"]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  statement {
    sid = "ManageEcrAccessPolicy"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyTags",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/ecr-access-${local.prefix}"]
  }

  statement {
    sid = "AttachEcrAccessPolicy"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-*"]
  }
}

data "aws_iam_policy_document" "maintenance_assume" {
  dynamic "statement" {
    for_each = length(var.nuon_support_iam_role_arns) > 0 ? [1] : []
    content {
      actions = ["sts:AssumeRole", "sts:TagSession"]
      principals {
        type        = "AWS"
        identifiers = var.nuon_support_iam_role_arns
      }
    }
  }

  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.runner.arn]
    }
  }
}

resource "aws_iam_policy" "maintenance_boundary" {
  name        = "${local.prefix}-maintenance-boundary"
  description = "Permissions boundary for the maintenance role."
  policy      = data.aws_iam_policy_document.maintenance_boundary.json
}

resource "aws_iam_role" "maintenance" {
  name        = "${local.prefix}-maintenance"
  description = "The only operation role this stack creates. Every Nuon job for this install assumes it."

  assume_role_policy   = data.aws_iam_policy_document.maintenance_assume.json
  permissions_boundary = aws_iam_policy.maintenance_boundary.arn

  tags = merge(local.tags, {
    Name = "${local.prefix}-maintenance"
  })
}

resource "aws_iam_role_policy" "maintenance" {
  name   = "${local.prefix}-maintenance-inline"
  role   = aws_iam_role.maintenance.id
  policy = data.aws_iam_policy_document.maintenance.json
}

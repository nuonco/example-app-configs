#
# A module to create a bucket for mattermost to use for file storage
#
locals {
  bucket_name = "${var.install_id}-nuon-mattermost"
  account_id  = data.aws_caller_identity.current.account_id
}

#
# KMS
#
data "aws_iam_policy_document" "mattermost_bucket_key_policy" {
  # enable IAM User Permissions
  statement {
    effect    = "Allow"
    actions   = ["kms:*", ]
    resources = ["*", ]
    principals {
      type        = "AWS"
      identifiers = [local.account_id, ]
    }
  }

  # allow all principals in this account that are authorized for s3
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*", ]
    principals {
      type        = "AWS"
      identifiers = ["*", ]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.region}.amazonaws.com", ]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [local.account_id, ]
    }
  }

}

resource "aws_kms_key" "mattermost_bucket" {
  description = "KMS key for ${local.bucket_name}"
  policy      = data.aws_iam_policy_document.mattermost_bucket_key_policy.json
}

resource "aws_kms_alias" "mattermost_bucket" {
  name          = "alias/bucket-key-${local.bucket_name}"
  target_key_id = aws_kms_key.mattermost_bucket.key_id
}

#
# IAM
#

# policy to allow access to this bucket: will be assigned to Mastermost's mm ServiceAccount specified in the Mattermost Installation manifest
# in the mattermost namespace

data "aws_iam_policy_document" "mattermost_bucket_access_policy" {
  # allow list bucket on this bucket
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
  }

  # allow all object actions on all objects in this bucket
  statement {
    effect    = "Allow"
    actions   = ["s3:*Object"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
  }
}

# so we can attach this to a role with which we tag the ServiceAccount
data "aws_iam_policy_document" "mattermost_trust_policy" {
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
      values   = ["system:serviceaccount:mattermost:mm"]
    }
  }
}

# role that can be assumed by the service account and has access to the bucket
resource "aws_iam_role" "mattermost_role" {
  name               = "${var.install_id}-nuon-mattermost-role"
  assume_role_policy = data.aws_iam_policy_document.mattermost_trust_policy.json

  # bucket access policy
  inline_policy {
    name   = "${var.install_id}-nuon-mattermost-role-inline-bucket-access-policy"
    policy = data.aws_iam_policy_document.mattermost_bucket_access_policy.json
  }

  tags = local.tags
}

#
# Bucket
#

module "mattermost_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = ">= v3.2.4"

  bucket = local.bucket_name
  versioning = {
    enabled = false
  }

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  attach_public_policy = false

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # the bucket access policy is inlined with the role
  # this bucket has no bucket policy to dictate access. access is exclusively managed through the role.
  # attach_policy = true
  # policy        = data.aws_iam_policy_document.s3_bucket_policy.json

  server_side_encryption_configuration = {
    rule : [
      {
        apply_server_side_encryption_by_default : {
          kms_master_key_id = aws_kms_key.mattermost_bucket.arn
          sse_algorithm : "aws:kms",
        },
        bucket_key_enabled : true,
      },
    ],
  }
}

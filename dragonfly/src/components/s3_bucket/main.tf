locals {
  bucket_name = "${var.install_id}-nuon-dragonfly"
  account_id  = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "dragonfly_bucket_key_policy" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [local.account_id]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.region}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_kms_key" "dragonfly_bucket" {
  description = "KMS key for ${local.bucket_name}"
  policy      = data.aws_iam_policy_document.dragonfly_bucket_key_policy.json
}

resource "aws_kms_alias" "dragonfly_bucket" {
  name          = "alias/bucket-key-${local.bucket_name}"
  target_key_id = aws_kms_key.dragonfly_bucket.key_id
}

data "aws_iam_policy_document" "dragonfly_bucket_access_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${local.bucket_name}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:HeadObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.dragonfly_bucket.arn]
  }
}

data "aws_iam_policy_document" "dragonfly_trust_policy" {
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
      values = [
        "system:serviceaccount:dragonfly:dragonfly",
      ]
    }
  }
}

resource "aws_iam_role" "dragonfly_role" {
  name               = "${var.install_id}-nuon-dragonfly-role"
  assume_role_policy = data.aws_iam_policy_document.dragonfly_trust_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "dragonfly_bucket_access" {
  name   = "${var.install_id}-nuon-dragonfly-bucket-access"
  role   = aws_iam_role.dragonfly_role.id
  policy = data.aws_iam_policy_document.dragonfly_bucket_access_policy.json
}

module "dragonfly_bucket" {
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
  object_ownership         = "BucketOwnerPreferred"

  force_destroy = true

  server_side_encryption_configuration = {
    rule : [
      {
        apply_server_side_encryption_by_default : {
          kms_master_key_id = aws_kms_key.dragonfly_bucket.arn
          sse_algorithm : "aws:kms",
        },
        bucket_key_enabled : true,
      },
    ],
  }

  lifecycle_rule = [
    {
      id      = "expire-snapshots"
      enabled = true
      filter = {
        prefix = "snapshots/"
      }
      expiration = {
        days = var.snapshot_retention_days
      }
      abort_incomplete_multipart_upload_days = 1
    },
  ]
}

resource "aws_s3_bucket_public_access_block" "dragonfly_bucket" {
  bucket = module.dragonfly_bucket.s3_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

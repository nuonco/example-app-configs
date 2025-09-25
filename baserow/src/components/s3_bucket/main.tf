locals {
  bucket_name = "baserow-files-${var.install_id}"
}

# S3 bucket for Baserow file storage
resource "aws_s3_bucket" "baserow_files" {
  bucket = local.bucket_name

  tags = {
    Name        = "Baserow Files"
    Environment = var.install_name
    ManagedBy   = "Nuon"
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "baserow_files" {
  bucket = aws_s3_bucket.baserow_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "baserow_files" {
  bucket = aws_s3_bucket.baserow_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "baserow_files" {
  bucket = aws_s3_bucket.baserow_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM policy for S3 access
resource "aws_iam_policy" "baserow_s3_policy" {
  name        = "BaserowS3Policy-${var.install_id}"
  path        = "/"
  description = "IAM policy for Baserow S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.baserow_files.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.baserow_files.arn
      }
    ]
  })
}

# IAM role for Baserow service account (IRSA)
resource "aws_iam_role" "baserow_role" {
  name = "BaserowRole-${var.install_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider
        }
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_provider, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "${replace(var.cluster_oidc_provider, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:sub" = "system:serviceaccount:baserow:baserow-*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "Baserow IRSA Role"
    Environment = var.install_name
    ManagedBy   = "Nuon"
  }
}

# Attach the S3 policy to the role
resource "aws_iam_role_policy_attachment" "baserow_s3_policy_attachment" {
  role       = aws_iam_role.baserow_role.name
  policy_arn = aws_iam_policy.baserow_s3_policy.arn
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
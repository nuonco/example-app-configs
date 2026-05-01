resource "aws_s3_bucket" "httpbin_bucket" {
  bucket = "httpbin-${var.install_id}-bucket"

  tags = {
    Name      = "httpbin-${var.install_id}-bucket"
    ManagedBy = "Nuon"
    InstallID = var.install_id
    Version   = "v2"
  }
}

resource "aws_s3_bucket_public_access_block" "httpbin_bucket" {
  bucket = aws_s3_bucket.httpbin_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# This resource often hits eventual consistency issues
# The bucket might not be fully propagated when this tries to apply
# causing transient failures that succeed on retry
resource "aws_s3_bucket_versioning" "httpbin_bucket" {
  bucket = aws_s3_bucket.httpbin_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration also prone to transient failures
# when the bucket is brand new
resource "aws_s3_bucket_lifecycle_configuration" "httpbin_bucket" {
  bucket = aws_s3_bucket.httpbin_bucket.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.httpbin_bucket]
}
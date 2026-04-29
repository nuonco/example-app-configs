resource "aws_s3_bucket" "httpbin_bucket" {
  bucket = "httpbin-${var.install_id}-bucket"

  tags = {
    Name      = "httpbin-${var.install_id}-bucket"
    ManagedBy = "Nuon"
    InstallID = var.install_id
  }
}

resource "aws_s3_bucket_public_access_block" "httpbin_bucket" {
  bucket = aws_s3_bucket.httpbin_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
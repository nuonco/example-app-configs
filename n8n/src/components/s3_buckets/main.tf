resource "aws_s3_bucket" "backups" {
  bucket = "${var.install_id}-n8n-backups"
  
  tags = merge(
    local.tags,
    {
      Name = "${var.install_id}-n8n-backups"
    }
  )
}

resource "aws_s3_bucket" "workflows" {
  bucket = "${var.install_id}-n8n-workflows"
  
  tags = merge(
    local.tags,
    {
      Name = "${var.install_id}-n8n-workflows"
    }
  )
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "workflows" {
  bucket = aws_s3_bucket.workflows.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "workflows" {
  bucket = aws_s3_bucket.workflows.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

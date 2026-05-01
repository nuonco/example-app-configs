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

# This resource will fail on the first 2 attempts, then succeed on the 3rd
# Perfect for demonstrating auto-retry functionality
resource "null_resource" "retry_demo" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      MARKER_FILE="/tmp/httpbin-retry-${var.install_id}.marker"
      
      # Check if marker file exists
      if [ ! -f "$MARKER_FILE" ]; then
        # First attempt - create marker with count 1 and fail
        echo "1" > "$MARKER_FILE"
        echo "First attempt - FAILING (this is expected)"
        exit 1
      fi
      
      # Read the current count
      COUNT=$(cat "$MARKER_FILE")
      
      if [ "$COUNT" -lt "2" ]; then
        # Second attempt - increment count and fail again
        NEW_COUNT=$((COUNT + 1))
        echo "$NEW_COUNT" > "$MARKER_FILE"
        echo "Retry attempt $COUNT - FAILING (this is expected)"
        exit 1
      fi
      
      # Third attempt or later - clean up and succeed
      rm -f "$MARKER_FILE"
      echo "Retry attempt $COUNT - SUCCESS!"
      exit 0
    EOT
    interpreter = ["bash", "-c"]
  }

  # This triggers the provisioner to run whenever the bucket changes
  triggers = {
    bucket_id = aws_s3_bucket.httpbin_bucket.id
  }
}
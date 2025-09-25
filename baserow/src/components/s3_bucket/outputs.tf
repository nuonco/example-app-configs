output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.baserow_files.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.baserow_files.arn
}

output "role_arn" {
  description = "ARN of the IAM role for service account"
  value       = aws_iam_role.baserow_role.arn
}

output "region" {
  description = "AWS region"
  value       = var.region
}
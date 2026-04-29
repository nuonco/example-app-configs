output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.httpbin_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.httpbin_bucket.arn
}

output "bucket_region" {
  description = "The region where the S3 bucket is located"
  value       = aws_s3_bucket.httpbin_bucket.region
}
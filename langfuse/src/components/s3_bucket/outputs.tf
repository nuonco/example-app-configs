output "langfuse_bucket" {
  value = {
    id          = module.langfuse_bucket.s3_bucket_id
    arn         = module.langfuse_bucket.s3_bucket_arn
    domain_name = module.langfuse_bucket.s3_bucket_bucket_domain_name
  }
}

output "bucket_name" {
  value = module.langfuse_bucket.s3_bucket_id
}

output "role_arn" {
  value = aws_iam_role.langfuse_role.arn
}

output "region" {
  value = var.region
}

output "kms_key_arn" {
  value = aws_kms_key.langfuse_bucket.arn
}

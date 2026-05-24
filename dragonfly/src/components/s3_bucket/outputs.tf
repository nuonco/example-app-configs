output "dragonfly_bucket" {
  value = {
    id          = module.dragonfly_bucket.s3_bucket_id
    arn         = module.dragonfly_bucket.s3_bucket_arn
    domain_name = module.dragonfly_bucket.s3_bucket_bucket_domain_name
  }
}

output "bucket_name" {
  value = module.dragonfly_bucket.s3_bucket_id
}

output "role_arn" {
  value = aws_iam_role.dragonfly_role.arn
}

output "region" {
  value = var.region
}

output "kms_key_arn" {
  value = aws_kms_key.dragonfly_bucket.arn
}


output "baserow_bucket" {
  value = {
    id          = module.baserow_bucket.s3_bucket_id
    arn         = module.baserow_bucket.s3_bucket_arn
    domain_name = module.baserow_bucket.s3_bucket_bucket_domain_name
  }
}

output "role_arn" {
  value = aws_iam_role.baserow_role.arn
}

output "bucket_name" {
  value = module.baserow_bucket.s3_bucket_id
}

output "region" {
  value = var.region
}

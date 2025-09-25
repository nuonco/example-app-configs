output "install_template_bucket" {
  value = {
    id          = module.install_template_bucket.s3_bucket_id
    arn         = module.install_template_bucket.s3_bucket_arn
    domain_name = module.install_template_bucket.s3_bucket_bucket_domain_name
    base_url    = "https://${module.install_template_bucket.s3_bucket_bucket_regional_domain_name}/"
    region      = module.install_template_bucket.s3_bucket_region
  }
}

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

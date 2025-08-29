output "install_template_bucket" {
  value = {
    id          = module.install_template_bucket.s3_bucket_id
    arn         = module.install_template_bucket.s3_bucket_arn
    domain_name = module.install_template_bucket.s3_bucket_bucket_domain_name
    base_url    = "https://${module.install_template_bucket.s3_bucket_bucket_regional_domain_name}/"
    region      = module.install_template_bucket.s3_bucket_region
  }
}

output "mattermost_bucket" {
  value = {
    id          = module.mattermost_bucket.s3_bucket_id
    arn         = module.mattermost_bucket.s3_bucket_arn
    domain_name = module.mattermost_bucket.s3_bucket_bucket_domain_name
  }
}

output "mattermost_bucket_role" {
  value = {
    arn = aws_iam_role.mattermost_role.arn
  }
}

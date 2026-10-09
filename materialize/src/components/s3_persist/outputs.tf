output "bucket_name" {
  value = module.materialize_bucket.s3_bucket_id
}

output "bucket_arn" {
  value = module.materialize_bucket.s3_bucket_arn
}

output "role_arn" {
  value = aws_iam_role.materialize_role.arn
}

output "region" {
  value = var.region
}

output "kms_key_arn" {
  value = aws_kms_key.materialize_bucket.arn
}

output "service_account_namespace" {
  value = local.sa_namespace
}

output "service_account_name" {
  value = local.sa_name
}

output "persist_prefix" {
  value = "system:serviceaccount:${local.sa_namespace}:${local.sa_name}"
}

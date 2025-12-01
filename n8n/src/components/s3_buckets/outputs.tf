output "backups_bucket" {
  value = {
    id  = aws_s3_bucket.backups.id
    arn = aws_s3_bucket.backups.arn
  }
}

output "workflows_bucket" {
  value = {
    id  = aws_s3_bucket.workflows.id
    arn = aws_s3_bucket.workflows.arn
  }
}

output "delegated_role_arn" {
  description = "ARN of the delegated IAM role created in the customer's account"
  value       = aws_iam_role.delegated.arn
}

output "delegated_role_name" {
  description = "Name of the delegated IAM role"
  value       = aws_iam_role.delegated.name
}

output "logs_policy_arn" {
  description = "ARN of the CloudWatch logs access policy"
  value       = aws_iam_policy.cloudwatch_logs_access.arn
}

output "cluster_read_policy_arn" {
  description = "ARN of the ECS cluster read access policy"
  value       = aws_iam_policy.ecs_cluster_read.arn
}

output "granted_permissions" {
  description = "Summary of permissions granted to the delegated role"
  value = {
    cloudwatch_logs = {
      actions  = ["logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:GetLogEvents", "logs:FilterLogEvents", "logs:GetLogGroupFields", "logs:GetLogRecord", "logs:GetQueryResults", "logs:StartQuery", "logs:StopQuery"]
      resource = var.cloudwatch_log_group_arn
    }
    ecs_cluster = {
      actions  = ["ecs:Describe*", "ecs:List*"]
      resource = var.cluster_arn
    }
  }
}

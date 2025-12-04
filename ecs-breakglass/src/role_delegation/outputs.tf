output "enabled" {
  description = "Whether role delegation is enabled"
  value       = local.enabled
}

output "delegated_role_arn" {
  description = "ARN of the delegated IAM role created in the customer's account"
  value       = local.enabled ? aws_iam_role.delegated[0].arn : null
}

output "delegated_role_name" {
  description = "Name of the delegated IAM role"
  value       = local.enabled ? aws_iam_role.delegated[0].name : null
}

output "logs_policy_arn" {
  description = "ARN of the CloudWatch logs access policy"
  value       = local.enabled ? aws_iam_policy.cloudwatch_logs_access[0].arn : null
}

output "cluster_read_policy_arn" {
  description = "ARN of the ECS cluster read access policy"
  value       = local.enabled ? aws_iam_policy.ecs_cluster_read[0].arn : null
}

output "granted_permissions" {
  description = "Summary of permissions granted to the delegated role"
  value = local.enabled ? {
    cloudwatch_logs = {
      actions  = ["logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:GetLogEvents", "logs:FilterLogEvents", "logs:GetLogGroupFields", "logs:GetLogRecord", "logs:GetQueryResults", "logs:StartQuery", "logs:StopQuery"]
      resource = var.cloudwatch_log_group_arn
    }
    ecs_cluster = {
      actions  = ["ecs:Describe*", "ecs:List*"]
      resource = var.cluster_arn
    }
  } : null
}

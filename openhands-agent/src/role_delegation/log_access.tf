resource "aws_iam_policy" "cloudwatch_logs_access" {
  count = local.enabled ? 1 : 0

  name        = "${local.prefix}-delegated-logs-access"
  description = "Policy granting read access to EKS cluster CloudWatch logs"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSCloudWatchLogsRead"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:GetLogGroupFields",
          "logs:GetLogRecord",
          "logs:GetQueryResults",
          "logs:StartQuery",
          "logs:StopQuery"
        ]
        Resource = [
          local.eks_log_group_arn,
          "${local.eks_log_group_arn}:*"
        ]
      }
    ]
  })
}

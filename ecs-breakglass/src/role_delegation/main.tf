locals {
  prefix  = var.nuon_id
  enabled = var.vendor_role_arn != ""
}

resource "aws_iam_role" "delegated" {
  count = local.enabled ? 1 : 0

  name        = "${local.prefix}-vendor-delegated"
  description = "Role allowing vendor cross-account access to this install's resources"
  tags        = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.vendor_role_arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cloudwatch_logs_access" {
  count = local.enabled ? 1 : 0

  name        = "${local.prefix}-delegated-logs-access"
  description = "Policy granting read access to CloudWatch logs for delegated role"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsRead"
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
          var.cloudwatch_log_group_arn,
          "${var.cloudwatch_log_group_arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_cluster_read" {
  count = local.enabled ? 1 : 0

  name        = "${local.prefix}-delegated-cluster-read"
  description = "Policy granting read access to ECS cluster for delegated role"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECSClusterRead"
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeContainerInstances",
          "ecs:ListServices",
          "ecs:ListTasks",
          "ecs:ListContainerInstances"
        ]
        Resource = [
          var.cluster_arn,
          "${replace(var.cluster_arn, ":cluster/", ":service/")}/*",
          "${replace(var.cluster_arn, ":cluster/", ":task/")}/*",
          "${replace(var.cluster_arn, ":cluster/", ":container-instance/")}/*"
        ]
      },
      {
        Sid    = "ECSTaskDefinitionRead"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "logs_access" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.delegated[0].name
  policy_arn = aws_iam_policy.cloudwatch_logs_access[0].arn
}

resource "aws_iam_role_policy_attachment" "cluster_read" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.delegated[0].name
  policy_arn = aws_iam_policy.ecs_cluster_read[0].arn
}

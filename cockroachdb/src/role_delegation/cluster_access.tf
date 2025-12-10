resource "aws_iam_policy" "eks_cluster_access" {
  count = local.enabled ? 1 : 0

  name        = "${local.prefix}-delegated-eks-access"
  description = "Policy granting read and scaling access to EKS cluster for delegated role"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSClusterRead"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates",
          "eks:ListClusters"
        ]
        Resource = [
          var.eks_cluster_arn,
          "${var.eks_cluster_arn}/*"
        ]
      },
      {
        Sid    = "EKSScaling"
        Effect = "Allow"
        Action = [
          "eks:UpdateNodegroupConfig"
        ]
        Resource = "${var.eks_cluster_arn}/nodegroup/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/install.nuon.co/id" = var.nuon_id
          }
        }
      },
      {
        Sid    = "AutoScalingRead"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeScalingActivities"
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingModify"
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:UpdateAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/install.nuon.co/id" = var.nuon_id
          }
        }
      }
    ]
  })
}

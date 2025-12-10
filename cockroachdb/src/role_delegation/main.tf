data "aws_caller_identity" "current" {}

locals {
  prefix  = var.nuon_id
  enabled = var.vendor_role_arn != ""

  # EKS cluster log group follows convention: /aws/eks/<cluster-name>/cluster
  eks_log_group_name = "/aws/eks/${var.eks_cluster_name}/cluster"
  eks_log_group_arn  = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.eks_log_group_name}"
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

resource "aws_iam_role_policy_attachment" "logs_access" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.delegated[0].name
  policy_arn = aws_iam_policy.cloudwatch_logs_access[0].arn
}

resource "aws_iam_role_policy_attachment" "eks_access" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.delegated[0].name
  policy_arn = aws_iam_policy.eks_cluster_access[0].arn
}

# EKS Access Entry - allows the delegated role to authenticate to the cluster
resource "aws_eks_access_entry" "delegated" {
  count = local.enabled ? 1 : 0

  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.delegated[0].arn
  type          = "STANDARD"

  tags = var.tags
}

# EKS Access Policy Association - grants Edit permissions for Karpenter scaling via kubectl
resource "aws_eks_access_policy_association" "delegated_edit" {
  count = local.enabled ? 1 : 0

  cluster_name  = var.eks_cluster_name
  principal_arn = aws_eks_access_entry.delegated[0].principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type = "cluster"
  }
}

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

output "eks_log_group_arn" {
  description = "ARN of the EKS cluster CloudWatch log group"
  value       = local.eks_log_group_arn
}

output "eks_access_policy_arn" {
  description = "ARN of the EKS cluster access policy"
  value       = local.enabled ? aws_iam_policy.eks_cluster_access[0].arn : null
}

output "eks_access_entry_arn" {
  description = "ARN of the EKS access entry for the delegated role"
  value       = local.enabled ? aws_eks_access_entry.delegated[0].access_entry_arn : null
}

output "granted_permissions" {
  description = "Summary of permissions granted to the delegated role"
  value = local.enabled ? {
    cloudwatch_logs = {
      actions  = ["logs:Describe*", "logs:Get*", "logs:FilterLogEvents", "logs:StartQuery", "logs:StopQuery"]
      resource = local.eks_log_group_arn
      note     = "EKS cluster control plane logs"
    }
    eks_cluster = {
      actions  = ["eks:Describe*", "eks:List*"]
      resource = var.eks_cluster_arn
    }
    eks_scaling = {
      actions   = ["eks:UpdateNodegroupConfig"]
      resource  = "${var.eks_cluster_arn}/nodegroup/*"
      condition = "aws:ResourceTag/install.nuon.co/id = ${var.nuon_id}"
    }
    autoscaling = {
      read_actions   = ["autoscaling:Describe*"]
      modify_actions = ["autoscaling:SetDesiredCapacity", "autoscaling:UpdateAutoScalingGroup"]
      condition      = "aws:ResourceTag/install.nuon.co/id = ${var.nuon_id}"
    }
    eks_access_entry = {
      policy = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
      scope  = "cluster"
      note   = "Allows kubectl access and Karpenter NodePool scaling"
    }
  } : null
}

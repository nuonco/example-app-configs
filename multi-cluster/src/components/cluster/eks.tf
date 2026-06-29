locals {
  cluster_name    = substr((var.cluster_name != "" ? var.cluster_name : var.nuon_id), 0, 38)
  cluster_version = var.cluster_version

  # access entries — these IAM roles are the runner roles. They are how the
  # runner authenticates to and operates against this cluster.
  default_access_entries = {
    "provision" = {
      principal_arn       = var.provision_iam_role_arn
      kubernetes_groups   = concat(["provision"], var.provision_role_eks_kubernetes_groups)
      policy_associations = var.provision_role_eks_access_entry_policy_associations,
      tags                = local.tags
    },
    "maintenance" = {
      principal_arn       = var.maintenance_iam_role_arn
      kubernetes_groups   = concat(["maintenance"], var.maintenance_role_eks_kubernetes_groups)
      policy_associations = var.maintenance_role_eks_access_entry_policy_associations,
      tags                = local.tags
    },
    "deprovision" = {
      principal_arn       = var.deprovision_iam_role_arn
      kubernetes_groups   = concat(["deprovision"], var.deprovision_role_eks_kubernetes_groups)
      policy_associations = var.deprovision_role_eks_access_entry_policy_associations,
      tags                = local.tags
    },
  }

  break_glass_access_entry = var.break_glass_iam_role_arn != "" ? {
    "break_glass" = {
      principal_arn       = var.break_glass_iam_role_arn
      kubernetes_groups   = concat(["break_glass"], var.break_glass_role_eks_kubernetes_groups)
      policy_associations = var.break_glass_role_eks_access_entry_policy_associations,
      tags                = local.tags
    }
  } : {}

  access_entries = merge(local.default_access_entries, local.break_glass_access_entry, var.additional_access_entry)
}

resource "aws_kms_key" "eks" {
  description = "Key for ${local.cluster_name} EKS cluster"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.9.0"

  name               = local.cluster_name
  kubernetes_version = local.cluster_version

  compute_config = var.eks_compute_config

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = local.subnets.private.ids

  endpoint_private_access = true
  endpoint_public_access  = var.cluster_endpoint_public_access

  authentication_mode                      = "API_AND_CONFIG_MAP"
  access_entries                           = local.access_entries
  enable_cluster_creator_admin_permissions = false

  enable_irsa = false

  # EBS CSI is handled natively by EKS Auto Mode (ebs.csi.eks.amazonaws.com).
  addons = {}

  tags = local.tags
}

# Allow the runner ASG to reach the cluster API endpoint. Required so the
# runner can manage the cluster post-provision via the IAM access entries above.
#
# NOTE: target the EKS-managed *primary* cluster SG, not the module's additional
# SG (`module.eks.cluster_security_group_id` in v21+ resolves to the additional
# SG). The primary SG is created and managed by EKS itself, is always attached
# to the API endpoint Hyperplane ENIs, and is never recreated — so an ingress
# rule placed here propagates instantly and is never silently disassociated
# from the ENIs by AWS during cluster lifecycle events (EKS Auto Mode in
# particular re-touches ENI SG associations on its own schedule, which dropped
# our second-apply traffic when the rule lived on the additional SG).
# Open the EKS API endpoint to the runner + private subnet CIDRs on both
# cluster SGs.
#
# Source-SG matching turned out to be unreliable here: the runner ASG attaches
# multiple SGs, AWS doesn't guarantee ordering on `vpc_security_group_ids`, and
# a tag-based aws_security_groups lookup can return the wrong SG entirely. A
# CIDR rule sidesteps all of that.
#
# We include the private subnet CIDRs in addition to the dedicated runner
# subnet: the sandbox node group (which hosts the runner pod) schedules into
# the private subnets, so under the default VPC CNI the runner's source IP is
# a private-subnet address, not a runner-subnet one.
#
# We attach to BOTH cluster SGs because the EKS module places the cross-account
# API endpoint ENIs behind both the AWS-managed primary cluster SG and the
# module's additional cluster SG; either one will be evaluated for ingress.
resource "aws_security_group_rule" "runner_cluster_access_primary" {
  type              = "ingress"
  description       = "Allow runner + private subnet ingress to EKS API endpoint (primary SG)."
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.eks.cluster_primary_security_group_id
  cidr_blocks       = concat(local.subnets.runner.cidrs, local.subnets.private.cidrs)

  depends_on = [module.eks]
}

resource "aws_security_group_rule" "runner_cluster_access_additional" {
  type              = "ingress"
  description       = "Allow runner + private subnet ingress to EKS API endpoint (additional SG)."
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.eks.cluster_security_group_id
  cidr_blocks       = concat(local.subnets.runner.cidrs, local.subnets.private.cidrs)

  depends_on = [module.eks]
}

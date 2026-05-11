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
resource "aws_security_group_rule" "runner_cluster_access" {
  type                     = "ingress"
  description              = "Allow ingress traffic from runner."
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = data.aws_security_groups.runner.ids[0]

  depends_on = [module.eks]
}

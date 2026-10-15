# No access policy associations: every permission comes from the Roles in rbac.tf.
resource "aws_eks_access_entry" "maintenance" {
  count = local.grant_maintenance_rbac ? 1 : 0

  cluster_name      = try(local.eks_cluster.name, null)
  principal_arn     = aws_iam_role.maintenance.arn
  type              = "STANDARD"
  kubernetes_groups = [local.maintenance_group]
}

resource "terraform_data" "maintenance_rbac_inputs" {
  input = {
    eks_cluster_name = local.eks_cluster_name
    namespaces       = local.maintenance_namespace_names
  }

  lifecycle {
    precondition {
      condition     = local.eks_cluster_name == "" || length(local.maintenance_namespace_names) > 0
      error_message = "cluster_name is set, but namespaces is empty. List the namespaces this install deploys into."
    }

    precondition {
      condition     = length(local.maintenance_namespace_names) == 0 || local.eks_cluster_name != ""
      error_message = "namespaces is set, but cluster_name is empty. Namespace RBAC is created on the cluster you pass in."
    }

    precondition {
      condition = alltrue([
        for ns in local.maintenance_namespace_names : can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", ns)) && length(ns) <= 63
      ])
      error_message = "Every namespace must be a DNS label of at most 63 characters."
    }
  }
}

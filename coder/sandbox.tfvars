ebs_storage_class = {
  enabled                = true
  name                   = "ebs-auto"
  is_default_class       = true
  provisioner            = "ebs.csi.eks.amazonaws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

cluster_endpoint_public_access = true

additional_namespaces = ["coder", "coder-observability"]

enable_irsa          = true

# adding additional permissions to maintenance role to run kubectl-based actions
# against the cluster (e.g. coder_db_init, which grants rds_iam / creates the
# coder_exporter user, and the psql-based healthcheck actions)

maintenance_role_eks_access_entry_policy_associations = {
  eks_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
  eks_view = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
}

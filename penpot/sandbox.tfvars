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

additional_namespaces = ["penpot"]

maintenance_cluster_role_rules_override = [{
  "apiGroups" = ["*"]
  "resources" = ["*"]
  "verbs"     = ["*"]
}]

min_size = 2
max_size = 3
desired_capacity = 2

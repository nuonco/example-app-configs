additional_namespaces = ["n8n"]


min_size         = {{ .nuon.inputs.inputs.min_size }}
max_size         = {{ .nuon.inputs.inputs.max_size }}
desired_capacity = {{ .nuon.inputs.inputs.desired_capacity }}


# Additional permissions for maintenance role to manage resources
maintenance_role_eks_access_entry_policy_associations = {
  eks_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
  eks_cluster_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
}


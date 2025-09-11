additional_namespaces = ["grafana", "exampledb"]


min_size             = {{ .nuon.inputs.inputs.min_size }}
max_size             = {{ .nuon.inputs.inputs.max_size }}
desired_capacity     = {{ .nuon.inputs.inputs.desired_capacity }}


# adding additional permissions to maintenance role to be able to create the postgres db secret

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

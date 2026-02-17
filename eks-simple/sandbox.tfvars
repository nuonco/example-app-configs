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

additional_namespaces = ["whoami"]

maintenance_cluster_role_rules_override = [{
  "apiGroups" = ["*"]
  "resources" = ["*"]
  "verbs"     = ["*"]
}]

min_size = 2
max_size = 3
desired_size = 2


{{ if gt (len .nuon.install_stack.outputs.break_glass_role_arns) 0 }}
break_glass_iam_role_arn = "{{ index (values .nuon.install_stack.outputs.break_glass_role_arns) 0 }}"

break_glass_role_eks_kubernetes_groups = []

break_glass_role_eks_access_entry_policy_associations = {
  cluster_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
  eks_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
}
{{ end }}

cluster_endpoint_public_access = true

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

additional_tags = {
  "app.nuon.co/name" : "programmable-runbook-and-readme"
}

eks_compute_config = {
  enabled    = true
  node_pools = ["general-purpose", "system"]
}

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

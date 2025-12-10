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

additional_namespaces = [
  "tailscale",
  "cockroach-operator-system",
  "cockroach",
]

additional_tags = {
  "app.nuon.co/name": "cockroachdb"
  "app.nuon.co/variant": "single-cluster"
  "app.nuon.co/tier": "public"
}


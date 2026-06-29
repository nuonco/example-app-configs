# Grant the maintenance role cluster-admin on this cluster via an EKS access
# entry. Component deploys run as the maintenance role, and the kubectl_manifest
# resources (namespaces, RBAC, storage class) need cluster-scope permissions to
# both refresh and apply — so without this the deploy 403s on clusterroles.
maintenance_role_eks_access_entry_policy_associations = {
  cluster_admin = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    access_scope = {
      type = "cluster"
    }
  }
}

namespaces = ["compute"]

node_pool_min_count  = 2
node_pool_max_count  = 3
node_pool_node_count = 2

additional_namespaces = ["sonarqube", "agic"]

maintenance_cluster_role_rules_override = [{
  "apiGroups" = ["*"]
  "resources" = ["*"]
  "verbs"     = ["*"]
}]

azure_rbac_roles = ["Azure Kubernetes Service Cluster Admin Role"]

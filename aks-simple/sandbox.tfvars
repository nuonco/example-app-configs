# Azure AKS Node Pool Configuration
node_pool_min_count = 2
node_pool_max_count = 3
node_pool_node_count = 2

# Additional Kubernetes namespaces
additional_namespaces = ["whoami"]

# Kubernetes RBAC configuration for maintenance role
maintenance_cluster_role_rules_override = [{
  "apiGroups" = ["*"]
  "resources" = ["*"]
  "verbs"     = ["*"]
}]

# Azure RBAC role assignments for maintenance role
# These will be mapped to Azure AKS built-in roles
azure_rbac_roles = ["Azure Kubernetes Service Cluster Admin Role"]

locals {
  maintenance_rbac_rules = [
    {
      api_groups = ["rbac.authorization.k8s.io"]
      resources  = ["roles", "rolebindings"]
      verbs      = ["bind", "create", "delete", "escalate", "get", "list", "patch", "update", "watch"]
    },
  ]

  maintenance_workload_rules = [
    {
      api_groups = ["apps"]
      resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
      verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
    },
    {
      api_groups = [""]
      resources  = ["pods", "services", "persistentvolumeclaims"]
      verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
    },
    {
      api_groups = [""]
      resources  = ["pods/log"]
      verbs      = ["get"]
    },
    {
      api_groups = [""]
      resources  = ["events"]
      verbs      = ["get", "list", "watch"]
    },
    {
      api_groups = ["networking.k8s.io"]
      resources  = ["ingresses"]
      verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
    },
  ]

  maintenance_control_rules = [
    {
      api_groups = [""]
      resources  = ["configmaps", "serviceaccounts"]
      verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
    },
    {
      api_groups = [""]
      resources  = ["secrets"]
      verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
    },
    {
      api_groups = ["batch"]
      resources  = ["jobs", "cronjobs"]
      verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
    },
    {
      api_groups = ["networking.k8s.io"]
      resources  = ["networkpolicies"]
      verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
    },
    {
      api_groups = [""]
      resources  = ["namespaces"]
      verbs      = ["get", "patch", "update"]
    },
  ]

  maintenance_cluster_read_rules = [
    {
      api_groups = [""]
      resources  = ["namespaces", "nodes", "persistentvolumes"]
      verbs      = ["get", "list", "watch"]
    },
    {
      api_groups = ["storage.k8s.io"]
      resources  = ["storageclasses"]
      verbs      = ["get", "list", "watch"]
    },
    {
      api_groups = ["networking.k8s.io"]
      resources  = ["ingressclasses", "networkpolicies"]
      verbs      = ["get", "list", "watch"]
    },
  ]

  maintenance_namespaced_roles = local.grant_maintenance_rbac ? {
    for ns in toset(local.maintenance_namespace_names) : ns => {
      namespace = ns
      rules     = concat(local.maintenance_rbac_rules, local.maintenance_workload_rules, local.maintenance_control_rules)
    }
  } : {}
}

resource "kubernetes_namespace_v1" "install" {
  for_each = local.maintenance_namespaced_roles

  metadata {
    name   = each.key
    labels = local.rbac_labels
  }
}

resource "kubernetes_role_v1" "maintenance" {
  for_each = local.maintenance_namespaced_roles

  metadata {
    name      = "${local.prefix}-maintenance"
    namespace = kubernetes_namespace_v1.install[each.key].metadata[0].name
    labels    = local.rbac_labels
  }

  dynamic "rule" {
    for_each = each.value.rules

    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_role_binding_v1" "maintenance" {
  for_each = local.maintenance_namespaced_roles

  metadata {
    name      = "${local.prefix}-maintenance"
    namespace = kubernetes_namespace_v1.install[each.key].metadata[0].name
    labels    = local.rbac_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.maintenance[each.key].metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.maintenance_group
  }
}

resource "kubernetes_cluster_role_v1" "maintenance_cluster_read" {
  count = local.grant_maintenance_rbac ? 1 : 0

  metadata {
    name   = "${local.prefix}-maintenance-cluster-read"
    labels = local.rbac_labels
  }

  dynamic "rule" {
    for_each = local.maintenance_cluster_read_rules

    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}

resource "kubernetes_cluster_role_binding_v1" "maintenance_cluster_read" {
  count = local.grant_maintenance_rbac ? 1 : 0

  metadata {
    name   = "${local.prefix}-maintenance-cluster-read"
    labels = local.rbac_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.maintenance_cluster_read[0].metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.maintenance_group
  }
}

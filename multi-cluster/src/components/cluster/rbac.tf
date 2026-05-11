locals {
  groups = {
    maintenance = {
      labels        = length(var.maintenance_cluster_role_rules_override) > 0 ? { "nuon.co/source" : "customer-defined" } : { "nuon.co/source" : "component-defaults" }
      role_binding  = "${path.module}/values/k8s/maintenance_rb.yaml"
      default_rules = yamldecode(file("${path.module}/values/k8s/maintenance_role.yaml")).rules
    }
  }
}

resource "kubectl_manifest" "maintenance" {
  provider = kubectl.main

  yaml_body = yamlencode({
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "ClusterRole"
    "metadata" = {
      "name"   = "maintenance"
      "labels" = local.groups.maintenance.labels
    }
    "rules" = length(var.maintenance_cluster_role_rules_override) > 0 ? var.maintenance_cluster_role_rules_override : tolist(local.groups.maintenance.default_rules)
  })
  depends_on = [
    module.eks,
    resource.aws_security_group_rule.runner_cluster_access,
  ]
}

resource "kubectl_manifest" "maintenance_role_binding" {
  provider = kubectl.main

  yaml_body = file(local.groups.maintenance.role_binding)
  depends_on = [
    module.eks,
    resource.aws_security_group_rule.runner_cluster_access,
  ]
}

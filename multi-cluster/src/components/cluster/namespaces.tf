locals {
  namespaces = concat([var.nuon_id], var.additional_namespaces)
}

resource "kubectl_manifest" "namespaces" {
  provider = kubectl.main

  for_each = toset(local.namespaces)
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = each.value
    }
  })

  depends_on = [
    module.eks,
    resource.aws_security_group_rule.runner_cluster_access,
  ]
}

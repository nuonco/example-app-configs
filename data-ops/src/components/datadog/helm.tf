locals {
  datadog = {
    value_file = "values/datadog-operator.yaml"
  }
}

resource "helm_release" "datadog" {
  count = local.enabled ? 1 : 0

  name             = local.name
  namespace        = local.namespace
  create_namespace = true

  repository = "https://helm.datadoghq.com"
  chart      = "datadog-operator"
  version    = "2.15.0"

  values = [
    file(local.datadog.value_file),
    yamlencode({
      clusterName = var.cluster_name
      site        = var.site
    })

  ]
}

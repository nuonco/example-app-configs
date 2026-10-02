# A raw manifest applied by terraform. Neither kind is in component health's core
# watch set, so both only report if the engine picks the kinds up out of
# terraform state.

resource "kubectl_manifest" "issuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "health-tf-selfsigned"
      namespace = var.namespace
    }
    spec = {
      selfSigned = {}
    }
  })
}

resource "kubectl_manifest" "certificate" {
  depends_on = [kubectl_manifest.issuer]

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "health-tf-cert"
      namespace = var.namespace
    }
    spec = {
      secretName = "health-tf-cert-tls"
      commonName = "health-tf.${var.namespace}.svc"
      dnsNames   = ["health-tf.${var.namespace}.svc"]
      issuerRef = {
        name = "health-tf-selfsigned"
        kind = "Issuer"
      }
    }
  })
}

resource "kubectl_manifest" "marker" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "health-tf-marker"
      namespace = var.namespace
    }
    data = {
      install = var.install_id
    }
  })
}

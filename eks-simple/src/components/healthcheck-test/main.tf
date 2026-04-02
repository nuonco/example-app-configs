terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

variable "namespace" {
  type    = string
  default = "healthcheck-test"
}

resource "kubectl_manifest" "namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${var.namespace}
  YAML
}

resource "kubectl_manifest" "deployment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-test
      namespace: ${var.namespace}
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: nginx-test
      template:
        metadata:
          labels:
            app: nginx-test
        spec:
          containers:
            - name: nginx
              image: nginx:this-tag-does-not-exist
              ports:
                - containerPort: 80
  YAML

  depends_on = [kubectl_manifest.namespace]
}

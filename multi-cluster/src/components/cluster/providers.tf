locals {
  k8s_exec = {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--region", var.region, "--cluster-name", module.eks.cluster_name]
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.default_tags
  }
}

# NOTE: every k8s-shaped provider below pins itself to *this* cluster only.
# `config_path = ""` / `config_paths = []` / `load_config_file = false` are set
# so the providers never silently fall back to ~/.kube/config, $KUBECONFIG, or
# in-cluster service-account credentials — which on the runner already point at
# the primary sandbox cluster.
#
# IMPORTANT: any kubernetes/helm/kubectl resource or sub-module added here MUST
# explicitly select these aliased providers via `provider = kubernetes.main`,
# `provider = helm.main`, or `provider = kubectl.main`. The runner injects
# `KUBECONFIG` and `KUBE_CONFIG_PATH` env vars that point at the SANDBOX
# cluster's kubeconfig (see runner internal/jobs/deploy/terraform/workspace.go).
# A resource without `provider = ...main` will fall back to the default
# provider config, pick up those env vars, and silently target the sandbox
# cluster instead of the cluster this component is provisioning.
provider "kubernetes" {
  alias = "main"

  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  config_path  = ""
  config_paths = []

  exec {
    api_version = local.k8s_exec.api_version
    command     = local.k8s_exec.command
    args        = local.k8s_exec.args
  }
}

provider "helm" {
  alias = "main"

  helm_driver = var.helm_driver

  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    config_path  = ""
    config_paths = []

    exec = {
      api_version = local.k8s_exec.api_version
      command     = local.k8s_exec.command
      args        = local.k8s_exec.args
    }
  }
}

provider "kubectl" {
  alias = "main"

  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = local.k8s_exec.api_version
    command     = local.k8s_exec.command
    args        = local.k8s_exec.args
  }
}

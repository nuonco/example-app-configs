terraform {
  required_version = ">= 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.21.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 3.1.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "= 1.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.38.0"
    }
  }
}

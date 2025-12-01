terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.67.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.17.0"
    }
    utils = {
      source  = "cloudposse/utils"
      version = "= 0.17.23"
    }
  }
}

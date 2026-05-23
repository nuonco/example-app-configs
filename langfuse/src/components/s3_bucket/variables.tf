locals {
  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "langfuse-bucket"
  }
}

variable "install_id" {
  type = string
}

variable "install_name" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_oidc_provider" {
  type = string
}

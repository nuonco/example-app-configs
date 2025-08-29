locals {
  install_templates_bucket_name = "${var.install_id}-byoc-nuon-install-templates"
  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "mattermost-buckets"
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

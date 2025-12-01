locals {
  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "n8n-buckets"
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

variable "backup_storage_gb" {
  type = string
}

variable "workflow_storage_gb" {
  type = string
}

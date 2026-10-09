locals {
  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "s3-persist"
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

variable "cluster_name" {
  type        = string
  description = "EKS cluster name for pod identity association"
}

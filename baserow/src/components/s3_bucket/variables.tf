variable "install_id" {
  description = "Unique identifier for the installation"
  type        = string
}

variable "install_name" {
  description = "Name of the installation"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_oidc_provider" {
  description = "OIDC provider for the cluster"
  type        = string
}
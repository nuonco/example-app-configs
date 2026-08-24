locals {
  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "coder-pod-identity"
  }
}

variable "install_id" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name — used to scope the aws_eks_pod_identity_association"
}

variable "db_instance_resource_id" {
  type        = string
  description = "Stable AWS DbiResourceId of the coder RDS instance, used to scope the rds-db:connect resource ARN"
}

variable "db_username" {
  type        = string
  default     = "coder"
  description = "Postgres user the Coder server connects as via IAM auth"
}

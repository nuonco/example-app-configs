locals {
  subnet_ids                          = split(",", trim(replace(var.subnet_ids, " ", ","), "[]"))
  iam_database_authentication_enabled = contains(["true", "1"], var.iam_database_authentication_enabled)
  deletion_protection                 = contains(["true", "1"], var.deletion_protection)
  multi_az                            = contains(["true", "1"], var.multi_az)
  skip_final_snapshot                 = contains(["true", "1"], var.skip_final_snapshot)
  storage_encrypted                   = contains(["true", "1"], var.storage_encrypted)
  apply_immediately                   = contains(["true", "1"], var.apply_immediately)
  tags = {
    "component.nuon.co/name" = "rds-cluster"
    "install.nuon.co/id"     = var.nuon_id
  }
}

variable "nuon_id" {
  type        = string
  description = "The Nuon Install ID"
}

variable "region" {
  type        = string
  description = "The AWS region"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = string
  description = "Comma-delimited string of subnet ids"
}

variable "subnet_group_id" {
  type        = string
  description = "The RDS subnet group for this RDS Cluster"
}

variable "identifier" {
  type        = string
  description = "Human friendly identifier for the cluster"
}

variable "port" {
  type    = string
  default = "5432"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type        = string
  description = "The name of the default database"
}

variable "db_user" {
  type        = string
  description = "The name of the admin user"
}

variable "iam_database_authentication_enabled" {
  type    = string
  default = "true"
}

variable "deletion_protection" {
  type    = string
  default = "false"
}

variable "apply_immediately" {
  type    = string
  default = "true"
}

variable "allocated_storage" {
  type    = string
  default = "20"
}

variable "multi_az" {
  type    = string
  default = "false"
}

variable "backup_retention_period" {
  type    = string
  default = "7"
}

variable "skip_final_snapshot" {
  type    = string
  default = "true"
}

variable "storage_encrypted" {
  type    = string
  default = "true"
}

variable "maintenance_window" {
  type    = string
  default = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  type    = string
  default = "03:00-06:00"
}

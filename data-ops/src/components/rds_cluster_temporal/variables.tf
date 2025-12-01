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
  description = "The Nuon Install ID ({{ .nuon.install.id }}."
}

variable "region" {
  type        = string
  description = "The AWS region ({{ .nuon.install_stack.outputs.region }}."
}

# network details
variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = string
  description = "Comma-delimited string of subnet ids to be split for use in this tf."
}

variable "subnet_group_id" {
  type        = string
  description = "The RDS subnet group for this RDS Cluster."
}

# database details
variable "identifier" {
  type        = string
  description = "Human friendly (ish) identifier for the cluster."
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
  description = "The name of the default database."
}

variable "db_user" {
  type        = string
  description = "The name of the admin user."
}

variable "iam_database_authentication_enabled" {
  type        = string
  description = "Whether or not the enable RDS IAM authentication."
  default     = "true"
}

variable "deletion_protection" {
  type        = string
  description = "Whether or not the enable deletion protection."
  default     = "false"
}

variable "apply_immediately" {
  type        = string
  description = "Set to true if the changes should be applied immediately."
  default     = "false"
}

variable "allocated_storage" {
  type        = string
  description = "Allocated storage"
  default     = 100
}

variable "multi_az" {
  type        = string
  description = "Enable multi-az."
  default     = "false"
}

variable "backup_retention_period" {
  type        = string
  description = "Backup retention period."
  default     = "1"
}

variable "skip_final_snapshot" {
  type        = string
  description = "Skip final snapshot."
  default     = "false"
}

variable "storage_encrypted" {
  type        = string
  description = "Encrypt storage."
  default     = "false"
}

variable "maintenance_window" {
  type        = string
  description = "Maintenance window."
  default     = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  type        = string
  description = "Backup window."
  default     = "03:00-06:00"
}

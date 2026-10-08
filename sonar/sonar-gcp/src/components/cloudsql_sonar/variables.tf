variable "install_id" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_self_link" {
  type        = string
  description = "VPC network self_link for Cloud SQL private IP access."
}

variable "tier" {
  type    = string
  default = "db-custom-2-8192"
}

variable "disk_size" {
  type    = number
  default = 100
}

variable "db_name" {
  type    = string
  default = "sonar"
}

variable "db_user" {
  type    = string
  default = "sonar"
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "install_id" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  type        = string
  description = "VPC network ID (self_link or id) to attach the private services connection to."
}

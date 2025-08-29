# https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest

variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = string
  default     = ""
}

variable "zone_id" {
  type = string
}

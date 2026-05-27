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
  type    = string
  default = ""
}

variable "zone_id" {
  type = string
}

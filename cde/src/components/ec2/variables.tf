variable "install_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id_0" {
  type = string
}

variable "subnet_id_1" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3a.large"
}

variable "ssh_public_key" {
  type = string
}

variable "os" {
  type    = string
  default = "ubuntu-24.04"
}

variable "install_vscode_web" {
  type    = string
  default = "false"
}

variable "anthropic_api_key" {
  type      = string
  default   = ""
  sensitive = true
}

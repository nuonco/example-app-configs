variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "install_id" {
  type = string
}

variable "appgw_subnet_cidr" {
  type        = string
  description = "CIDR for the Application Gateway subnet; must fit the install VNet."
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "oidc_issuer_url" {
  type        = string
  description = "AKS OIDC issuer URL for AGIC workload identity federation."
  default     = ""
}

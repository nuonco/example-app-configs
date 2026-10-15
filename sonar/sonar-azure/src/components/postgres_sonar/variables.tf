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

variable "postgres_subnet_cidr" {
  type        = string
  description = "CIDR for the delegated PostgreSQL Flexible Server subnet; must fit the install VNet."
}

variable "sku_name" {
  type    = string
  default = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "db_name" {
  type    = string
  default = "sonar"
}

variable "db_user" {
  type    = string
  default = "sonar"
}

variable "tags" {
  type    = map(string)
  default = {}
}

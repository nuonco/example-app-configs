variable "nuon_id" {
  description = "Nuon Install ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Subnet delegated to Microsoft.App/environments"
  type        = string
}



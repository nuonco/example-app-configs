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

variable "container_app_environment_id" {
  description = "ID of the ACA environment from the sandbox"
  type        = string
}

variable "acr_login_server" {
  description = "ACR login server for pulling images"
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID for role assignment"
  type        = string
}

variable "image_repository" {
  description = "Whoami container image repository"
  type        = string
}

variable "image_tag" {
  description = "Whoami container image tag"
  type        = string
}

variable "cpu" {
  description = "CPU cores for the container (e.g. 0.25, 0.5, 1.0)"
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory in Gi for the container (e.g. 0.5Gi, 1Gi)"
  type        = string
  default     = "0.5Gi"
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3
}

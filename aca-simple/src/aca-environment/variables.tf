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

variable "workload_profile_type" {
  description = "Workload profile type for the ACA environment"
  type        = string
  default     = "D4"
}

variable "workload_profile_min" {
  description = "Minimum number of workload profile instances"
  type        = number
  default     = 0
}

variable "workload_profile_max" {
  description = "Maximum number of workload profile instances"
  type        = number
  default     = 3
}

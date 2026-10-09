variable "prefix" {
  type        = string
  description = "Resource name prefix (typically the Nuon install ID)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID the runner ASG runs in."
}

variable "runner_subnet_id" {
  type        = string
  description = "Subnet ID for runner instances."
}

variable "runner_security_group" {
  type        = string
  description = "Security group ID attached to runner instances."
}

variable "runner_instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile attached to runner instances."
}

variable "runner_api_url" {
  type        = string
  description = "Nuon runner API URL."
}

variable "runner_id" {
  type        = string
  description = "Nuon runner ID."
}

variable "nuon_install_id" {
  type        = string
  description = "Nuon install ID."
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for the runner."
}

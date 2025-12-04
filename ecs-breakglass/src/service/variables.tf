locals {
  prefix = var.nuon_id
  tags   = var.tags
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "nuon_id" {
  description = "Nuon Install ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "image_repository" {
  description = "Whoami Service Image Repository"
  type        = string
}

variable "image_tag" {
  description = "Whoami Service Image Tag"
  type        = string
}

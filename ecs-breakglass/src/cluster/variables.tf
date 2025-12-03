locals {
  prefix                = var.nuon_id
  vpc_id                = var.vpc_id
  private_subnet_ids    = local.subnets.private.ids
  alb_security_group_id = var.alb_security_group_id
  ecs_instance_type     = var.ecs_instance_type
  ecs_min_size          = var.ecs_min_size
  ecs_max_size          = var.ecs_max_size
  ecs_desired_capacity  = var.ecs_desired_capacity
  tags = merge(var.tags,
    {
      "install.nuon.co/id"     = var.nuon_id
      "component.nuon.co/name" = "ecs-cluster"
    }
  )
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
  description = "VPC ID where ECS cluster will be deployed"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB (optional, for ingress rules)"
  type        = string
  default     = null
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS container instances"
  type        = string
  default     = "t3.medium"
}

variable "ecs_min_size" {
  description = "Minimum number of EC2 instances in the ECS cluster"
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of EC2 instances in the ECS cluster"
  type        = number
  default     = 4
}

variable "ecs_desired_capacity" {
  description = "Desired number of EC2 instances in the ECS cluster"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

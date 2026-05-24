locals {
  subnet_ids = split(",", trim(replace(var.subnet_ids, " ", ","), "[]"))
  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "elasticache-redis"
  }
}

variable "install_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = string
  description = "Comma-delimited string of private subnet ids for the cache subnet group"
}

variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "port" {
  type    = string
  default = "6379"
}

variable "engine_version" {
  type        = string
  default     = "8.0"
  description = "Valkey engine version. AWS supports 7.x and 8.x families."
}

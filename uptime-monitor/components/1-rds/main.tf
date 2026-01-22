# -----------------------------------------------------------------------------
# RDS PostgreSQL for Uptime Monitor
# -----------------------------------------------------------------------------
#
# Variables are passed from the Nuon component config (1-rds.toml):
#   - var.region                 <- {{.nuon.install_stack.outputs.region}}
#   - var.install_id             <- {{.nuon.install.id}}
#   - var.vpc_id                 <- {{.nuon.install.sandbox.outputs.vpc.id}}
#   - var.private_subnet_ids     <- {{.nuon.install.sandbox.outputs.vpc.private_subnet_ids}}
#   - var.node_security_group_id <- {{.nuon.install.sandbox.outputs.cluster.node_security_group_id}}
#
# Outputs are available to other components via:
#   {{.nuon.components.rds.outputs.db_host}}
#   {{.nuon.components.rds.outputs.db_port}}
#   {{.nuon.components.rds.outputs.db_name}}
#   {{.nuon.components.rds.outputs.db_username}}
#   {{.nuon.components.rds.outputs.master_user_secret_arn}}
#
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Nuon tagging convention for resource tracking
  default_tags {
    tags = {
      "install.nuon.co/id"     = var.install_id
      "component.nuon.co/name" = "rds"
    }
  }
}

# Variables passed from Nuon component config
variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

# From sandbox outputs: {{.nuon.install.sandbox.outputs.vpc.id}}
variable "vpc_id" {
  type        = string
  description = "VPC ID from the sandbox"
}

# From sandbox outputs: {{.nuon.install.sandbox.outputs.vpc.private_subnet_ids}}
variable "private_subnet_ids" {
  type        = string
  description = "Comma-delimited string of private subnet IDs from the sandbox"
}

# From sandbox outputs: {{.nuon.install.sandbox.outputs.cluster.node_security_group_id}}
variable "node_security_group_id" {
  type        = string
  description = "EKS node security group ID from the sandbox"
}

# Get VPC CIDR block
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# Security group for RDS
resource "aws_security_group" "postgres" {
  name_prefix = "${var.install_id}-postgres-"
  description = "Security group for PostgreSQL RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    description = "Allow PostgreSQL access from within VPC"
  }

  tags = {
    Name = "${var.install_id}-postgres-sg"
  }
}

# RDS subnet group
resource "aws_db_subnet_group" "postgres" {
  name_prefix = "${var.install_id}-postgres-"
  subnet_ids  = split(",", var.private_subnet_ids)

  tags = {
    Name = "${var.install_id}-postgres-subnet-group"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier_prefix = "${var.install_id}-postgres-"

  engine         = "postgres"
  engine_version = "18"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"

  db_name  = "uptime_monitor"
  username = "uptime_monitor"

  # AWS manages password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = false

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.install_id}-postgres"
  }
}

# Outputs - referenced by other Nuon components and actions
output "db_host" {
  value       = aws_db_instance.postgres.address
  description = "PostgreSQL database host"
}

output "db_port" {
  value       = aws_db_instance.postgres.port
  description = "PostgreSQL database port"
}

output "db_name" {
  value       = aws_db_instance.postgres.db_name
  description = "PostgreSQL database name"
}

output "db_username" {
  value       = aws_db_instance.postgres.username
  description = "PostgreSQL database username"
}

output "master_user_secret_arn" {
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
  description = "ARN of the Secrets Manager secret containing username/password"
}

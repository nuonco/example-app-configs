# -----------------------------------------------------------------------------
# S3 Bucket for Uptime Monitor
# -----------------------------------------------------------------------------
#
# Variables are passed from the Nuon component config (1-s3.toml):
#   - var.region     <- {{.nuon.install_stack.outputs.region}}
#   - var.install_id <- {{.nuon.install.id}}
#
# Outputs are available to other components via:
#   {{.nuon.components.s3.outputs.bucket_name}}
#   {{.nuon.components.s3.outputs.bucket_arn}}
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
      "component.nuon.co/name" = "s3"
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

locals {
  bucket_name = "${var.install_id}-uptime-monitor"
}

# S3 bucket
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name
}

# Outputs - referenced by other Nuon components
output "bucket_name" {
  value       = aws_s3_bucket.main.bucket
  description = "S3 bucket name"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "S3 bucket ARN"
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "nuon_id" {
  description = "Nuon Install ID"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for the service"
  type        = string
}

variable "vendor_role_arn" {
  description = "ARN of the vendor's IAM role to grant cross-account access. If empty, no resources are created."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

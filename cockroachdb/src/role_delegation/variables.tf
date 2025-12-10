variable "region" {
  description = "AWS Region"
  type        = string
}

variable "nuon_id" {
  description = "Nuon Install ID"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
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

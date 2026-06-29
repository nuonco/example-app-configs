variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids."
  default     = []
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet ids."
  default     = []
}

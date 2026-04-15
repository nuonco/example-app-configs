variable "images" {
  description = "JSON-encoded list of container images to pre-cache on the AMI"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the builder instance will launch"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the builder instance. Must have outbound internet access (NAT gateway) for pulling images from public registries."
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version (e.g. 1.32). Used to select the matching EKS-optimized AMI as the base."
  type        = string
  default     = "1.32"
}

variable "volume_size_gb" {
  description = "Size of the root EBS volume in GB. Must be large enough to hold the base AMI plus all specified container images."
  type        = number
  default     = 100
}

variable "instance_type" {
  description = "EC2 instance type for the builder. Larger instances pull images faster due to higher network bandwidth."
  type        = string
  default     = "m5.xlarge"
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}

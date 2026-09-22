variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "install_id" {
  type = string
}

variable "image_repository" {
  type        = string
  description = "ECR repository the whoami image was mirrored into"
}

variable "image_tag" {
  type        = string
  description = "Digest-pinned tag of the mirrored whoami image"
}

variable "install_id" {
  description = "Nuon install ID for resource tagging"
  type        = string
}

variable "region" {
  description = "AWS region for Lambda deployment"
  type        = string
  default     = "us-west-2"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "image_uri" {
  description = "URI of the Docker image in ECR"
  type        = string
}

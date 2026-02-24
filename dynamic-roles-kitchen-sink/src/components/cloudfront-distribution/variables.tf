variable "install_id" {
  description = "Nuon install ID for resource tagging"
  type        = string
}

variable "distribution_name" {
  description = "Name/comment for the CloudFront distribution"
  type        = string
}

variable "lambda_function_url" {
  description = "URL of the Lambda function to use as origin"
  type        = string
}

variable "domain_name" {
  description = "Optional custom domain name for CloudFront"
  type        = string
  default     = ""
}

variable "function_name" {
  type = string
}

variable "image_uri" {
  type = string
}

variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

variable "api_key" {
  type        = string
  description = "API key for authenticating requests"
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "Secret key for JWT token signing"
  sensitive   = true
}

variable "encryption_key" {
  type        = string
  description = "Encryption key for securing sensitive data"
  sensitive   = true
}

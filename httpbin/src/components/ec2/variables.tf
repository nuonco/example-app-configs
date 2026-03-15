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

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "http_port" {
  type    = string
  default = "80"
}

variable "httpbin_version" {
  type    = string
  default = "latest"
}

variable "allowed_ips" {
  type    = string
  default = "0.0.0.0/0"
}

variable "max_response_size" {
  type    = string
  default = "10485760"
}

variable "max_duration" {
  type    = string
  default = "10"
}

variable "log_level" {
  type    = string
  default = "info"
}

variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

variable "name" {
  type = string
}

variable "hash_key" {
  type = string
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

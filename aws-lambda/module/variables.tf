variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "template_url" {
  type = string
}

variable "parameters" {
  type    = map(string)
  default = {}
}

variable "capabilities" {
  type    = list(string)
  default = []
}

variable "on_failure" {
  type    = string
  default = "ROLLBACK"
}

variable "timeout_in_minutes" {
  type    = number
  default = 30
}

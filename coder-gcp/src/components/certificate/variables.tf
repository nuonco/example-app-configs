variable "install_id" {
  type = string
}

variable "project_id" {
  type = string
}

variable "domain_name" {
  type        = string
  description = "Apex domain for the wildcard cert (e.g. <install>.nuon.run). Workspace subdomains are validated via wildcard."
}

variable "dns_zone_name" {
  type        = string
  description = "Cloud DNS managed zone name for cert validation."
}

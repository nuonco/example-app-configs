variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

variable "cluster_endpoint" {
  type        = string
  description = "GKE cluster API endpoint."
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "GKE cluster CA certificate (base64)."
}

variable "domain_filters" {
  type        = string
  description = "Comma-separated public domains external-dns is allowed to manage."
}

variable "internal_domain_filters" {
  type        = string
  description = "Comma-separated internal/private domains external-dns is allowed to manage."
}

variable "chart_version" {
  type        = string
  description = "external-dns Helm chart version."
  default     = "1.20.0"
}

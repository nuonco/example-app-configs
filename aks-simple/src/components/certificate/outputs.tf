output "tls_secret_name" {
  value = "${var.install_id}-tls"
}

output "app_url" {
  value = "https://${var.domain_name}"
}

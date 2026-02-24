resource "google_compute_managed_ssl_certificate" "main" {
  project = var.project_id
  name    = "${var.install_id}-cert"

  managed {
    domains = [var.domain_name]
  }
}

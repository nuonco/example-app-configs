output "certificate_name" {
  value = google_compute_managed_ssl_certificate.main.name
}

output "certificate_id" {
  value = google_compute_managed_ssl_certificate.main.id
}

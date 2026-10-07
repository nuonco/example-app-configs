output "certificate_id" {
  value = google_certificate_manager_certificate.apex_wildcard.id
}

output "certificate_name" {
  value = google_certificate_manager_certificate.apex_wildcard.name
}

output "cert_map_name" {
  value = google_certificate_manager_certificate_map.default.name
}

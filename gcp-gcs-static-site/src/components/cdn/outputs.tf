output "cdn_ip" {
  value = google_compute_global_forwarding_rule.site.ip_address
}

output "site_url" {
  value = "http://${google_compute_global_forwarding_rule.site.ip_address}"
}

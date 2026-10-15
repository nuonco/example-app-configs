output "network_self_link" {
  value       = var.network_id
  description = "VPC network passed through for downstream Cloud SQL components."
}

output "peering_range" {
  value       = google_compute_global_address.private_services.name
  description = "Reserved peering range name."
}

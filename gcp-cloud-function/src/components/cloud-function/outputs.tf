output "function_url" {
  value = google_cloud_run_v2_service.function.uri
}

output "function_name" {
  value = google_cloud_run_v2_service.function.name
}

output "function_status" {
  value = google_cloud_run_v2_service.function.reconciliation
}

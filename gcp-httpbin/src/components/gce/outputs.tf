output "instance_name" {
  value = google_compute_instance.httpbin.name
}

output "zone" {
  value = google_compute_instance.httpbin.zone
}

output "public_ip" {
  value = google_compute_instance.httpbin.network_interface[0].access_config[0].nat_ip
}

output "url" {
  value = "http://${google_compute_instance.httpbin.network_interface[0].access_config[0].nat_ip}"
}

output "name" {
  value = data.google_storage_bucket.main.name
}

output "url" {
  value = data.google_storage_bucket.main.url
}

output "self_link" {
  value = data.google_storage_bucket.main.self_link
}

output "marker_object" {
  value = "gs://${data.google_storage_bucket.main.name}/${google_storage_bucket_object.marker.name}"
}

output "bucket_name" {
  value = google_storage_bucket.site.name
}

output "bucket_url" {
  value = google_storage_bucket.site.self_link
}

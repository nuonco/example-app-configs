resource "google_storage_bucket" "wi_demo" {
  project                     = var.project_id
  name                        = "wi-demo-${var.install_id}"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "test" {
  bucket  = google_storage_bucket.wi_demo.name
  name    = "test.txt"
  content = "Workload Identity works! Install: ${var.install_id}"
}

resource "google_storage_bucket_iam_member" "object_viewer" {
  bucket = google_storage_bucket.wi_demo.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account_email}"
}

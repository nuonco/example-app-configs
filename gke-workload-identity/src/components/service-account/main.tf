resource "google_service_account" "wi_demo" {
  project      = var.project_id
  account_id   = "wi-demo-${substr(var.install_id, 0, 12)}"
  display_name = "wi-demo for ${var.install_id}"
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.wi_demo.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/wi-demo]"
}

resource "google_project_iam_member" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.wi_demo.email}"
}

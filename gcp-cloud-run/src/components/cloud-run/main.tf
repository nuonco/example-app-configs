resource "google_cloud_run_v2_service" "this" {
  name     = "whoami-${var.install_id}"
  location = var.region
  project  = var.project_id

  template {
    containers {
      image = var.image

      ports {
        container_port = 80
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.this.name
  location = google_cloud_run_v2_service.this.location
  project  = google_cloud_run_v2_service.this.project
  role     = "roles/run.invoker"
  member   = "allUsers"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_v2_service" "function" {
  name     = "nuon-fn-${var.install_id}"
  location = var.region

  template {
    containers {
      image = var.image_url

      env {
        name  = "INSTALL_ID"
        value = var.install_id
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    service_account = google_service_account.function_sa.email
  }

  labels = {
    "install-nuon-co-id"     = var.install_id
    "component-nuon-co-name" = "cloud-function"
  }
}

resource "google_service_account" "function_sa" {
  account_id   = "nuon-fn-${substr(var.install_id, 0, 20)}"
  display_name = "Nuon Cloud Function ${var.install_id}"
}

resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.function.location
  name     = google_cloud_run_v2_service.function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

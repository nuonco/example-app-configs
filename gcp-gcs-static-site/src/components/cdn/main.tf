resource "google_compute_backend_bucket" "site" {
  name        = "static-site-backend-${var.project_id}"
  bucket_name = var.bucket_name
  project     = var.project_id
  enable_cdn  = true
}

resource "google_compute_url_map" "site" {
  name            = "static-site-${var.project_id}"
  project         = var.project_id
  default_service = google_compute_backend_bucket.site.id
}

resource "google_compute_target_http_proxy" "site" {
  name    = "static-site-proxy-${var.project_id}"
  project = var.project_id
  url_map = google_compute_url_map.site.id
}

resource "google_compute_global_forwarding_rule" "site" {
  name       = "static-site-fwd-${var.project_id}"
  project    = var.project_id
  target     = google_compute_target_http_proxy.site.id
  port_range = "80"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

data "google_compute_image" "cos" {
  project = "cos-cloud"
  family  = "cos-stable"
}

locals {
  name = "httpbin-${var.install_id}"
  labels = {
    "install-nuon-co-id"     = var.install_id
    "component-nuon-co-name" = "gce"
  }
}

resource "google_compute_firewall" "httpbin" {
  project = var.project_id
  name    = "${local.name}-http"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.name]
}

resource "google_compute_instance" "httpbin" {
  project      = var.project_id
  name         = local.name
  zone         = data.google_compute_zones.available.names[0]
  machine_type = "e2-micro"
  tags         = [local.name]
  labels       = local.labels

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    docker run -d --name httpbin --restart unless-stopped -p 80:8080 ghcr.io/mccutchen/go-httpbin:2.18.2
  EOF

  allow_stopping_for_update = true

  depends_on = [google_compute_firewall.httpbin]
}

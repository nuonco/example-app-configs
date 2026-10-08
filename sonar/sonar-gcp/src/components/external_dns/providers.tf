provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  }
}

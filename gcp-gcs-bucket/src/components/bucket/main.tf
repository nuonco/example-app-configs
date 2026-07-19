# The install stack's custom stack creates the bucket as <install-id>-<stack key>.
data "google_storage_bucket" "main" {
  name = "${var.install_id}-storage"
}

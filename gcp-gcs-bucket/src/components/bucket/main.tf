# The install stack's custom stack creates the bucket as <install-id>-<stack key>.
data "google_storage_bucket" "main" {
  name = "${var.install_id}-storage"
}

# Proof of life: written on every deploy so the bucket is verifiably usable.
resource "google_storage_bucket_object" "marker" {
  bucket  = data.google_storage_bucket.main.name
  name    = "nuon/installed-by.txt"
  content = "install ${var.install_id}"
}

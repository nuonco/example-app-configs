resource "aws_s3_bucket" "demo" {
  bucket = "${var.install_id}-policies-demo"
}

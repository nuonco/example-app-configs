output "public_ip" {
  value = module.ec2_instance.public_ip
}

output "image" {
  value = "${var.image_repository}:${var.image_tag}"
}

output "ami_id" {
  description = "ID of the custom AMI containing pre-cached container images"
  value       = aws_ami_from_instance.cache.id
}

output "volume_size_gb" {
  description = "Root volume size in GB (must match blockDeviceMappings in EC2NodeClass)"
  value       = var.volume_size_gb
}

output "gvisor_version" {
  description = "gVisor release baked into the AMI"
  value       = var.gvisor_version
}

output "runtime_handler" {
  description = "containerd runtime name registered for gVisor, used as the RuntimeClass handler"
  value       = "runsc"
}

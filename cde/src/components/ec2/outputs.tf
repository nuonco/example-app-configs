output "instance_id" {
  value = aws_instance.dev_env.id
}

output "elastic_ip" {
  value = aws_eip.dev_env.public_ip
}

output "ssh_hostname" {
  value = aws_route53_record.ssh.fqdn
}

output "ssh_user" {
  value = local.ssh_user
}

output "vscode_url" {
  value = local.install_vscode_web ? "https://${aws_route53_record.vscode[0].fqdn}" : ""
}

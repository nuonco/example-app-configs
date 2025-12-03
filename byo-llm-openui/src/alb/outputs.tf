output "dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "app_target_group_arn" {
  description = "ARN of the app target group"
  value       = aws_lb_target_group.app.arn
}

output "app_url" {
  description = "URL to access the app"
  value       = "https://${local.app_domain_name}"
}

output "app_fqdn" {
  description = "App fully qualified domain name"
  value       = aws_route53_record.app.fqdn
}

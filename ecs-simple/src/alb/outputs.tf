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

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "url" {
  description = "URL to access the service"
  value       = "https://${var.domain_name}"
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = aws_route53_record.this.fqdn
}

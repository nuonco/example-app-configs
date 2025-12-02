output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "security_group_id" {
  description = "Security group ID of the ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

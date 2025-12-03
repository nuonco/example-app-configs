output "cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs_cluster.cluster_id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.cluster_name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group for EC2 instances"
  value       = aws_autoscaling_group.ecs.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group for EC2 instances"
  value       = aws_autoscaling_group.ecs.arn
}

output "ecs_instance_security_group_id" {
  description = "Security group ID for ECS EC2 instances"
  value       = aws_security_group.ecs_instances.id
}

output "ecs_instance_role_name" {
  description = "IAM role name for ECS EC2 instances"
  value       = aws_iam_role.ecs_instance.name
}

output "ecs_instance_role_arn" {
  description = "IAM role ARN for ECS EC2 instances"
  value       = aws_iam_role.ecs_instance.arn
}

output "capacity_providers" {
  description = "List of capacity providers configured for the cluster"
  value = {
    ec2          = "ec2"
    fargate      = "FARGATE"
    fargate_spot = "FARGATE_SPOT"
  }
}

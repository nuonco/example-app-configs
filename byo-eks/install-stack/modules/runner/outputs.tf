output "asg_name" {
  value = aws_autoscaling_group.runner.name
}

output "asg_arn" {
  value = aws_autoscaling_group.runner.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.runner.name
}

output "launch_template_id" {
  value = aws_launch_template.runner.id
}

output "ami_id" {
  value = data.aws_ami.al2023.id
}

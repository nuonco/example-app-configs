# Output names mirror the CloudFormation phone-home Lambda payload
# so anything reading `terraform output` or `nuon.install_stack.outputs.*` sees
# the same key set whether the install was applied via CFN or Terraform.

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = var.aws_region
}

output "vpc_id" {
  value = var.vpc_id
}

output "runner_subnet" {
  value = var.runner_subnet_id
}

output "public_subnets" {
  value = var.public_subnet_ids
}

output "private_subnets" {
  value = var.private_subnet_ids
}

output "runner_iam_role_arn" {
  value = aws_iam_role.runner.arn
}

output "runner_instance_profile" {
  value = aws_iam_instance_profile.runner.arn
}

output "runner_asg_name" {
  value = local.runner_asg_name
}

output "runner_log_group_name" {
  value = local.runner_log_group_name
}

output "provision_iam_role_arn" {
  value = aws_iam_role.maintenance.arn
}

output "maintenance_iam_role_arn" {
  value = aws_iam_role.maintenance.arn
}

output "deprovision_iam_role_arn" {
  value = aws_iam_role.maintenance.arn
}

output "break_glass_role_arns" {
  value       = local.break_glass_role_arns
  description = "Map of break-glass role name to IAM role ARN."
}

output "custom_role_arns" {
  value       = local.custom_role_arns
  description = "Map of custom role name to IAM role ARN."
}

# Always present, even when no custom stacks are defined, so the shape matches
# the CFN payload.
output "custom_nested_stacks" {
  value = {}
}

output "install_inputs" {
  value       = var.install_inputs
  description = "Customer-provided install inputs passed back to Nuon."
}

# Secrets — emitted individually as `<name>_arn` to match the flattened CFN
# Lambda payload. Also exposed as a single map for convenience.
output "secret_arns" {
  value       = local.all_secret_arns
  description = "Map of <secret_name>_arn to AWS Secrets Manager ARN. Each entry is also exposed as its own top-level output."
}

output "runner_security_group_id" {
  value = aws_security_group.runner.id
}

output "runner_enabled" {
  value = var.runner_enabled
}

output "maintenance_kubernetes_group" {
  description = "Kubernetes group on the maintenance access entry. Empty when no cluster ARN was provided."
  value       = local.grant_maintenance_rbac ? local.maintenance_group : ""
}

output "eks_access_entry_namespaces" {
  description = "Namespaces the maintenance role can manage. Empty when Kubernetes RBAC was not created."
  value       = local.grant_maintenance_rbac ? sort(tolist(toset(local.maintenance_namespace_names))) : []
}

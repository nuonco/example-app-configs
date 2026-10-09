locals {
  break_glass_role_arns = { for k, v in aws_iam_role.break_glass : k => v.arn }
  custom_role_arns      = { for k, v in aws_iam_role.custom : k => v.arn }

  all_secret_arns = {}

  # Key names below mirror the CloudFormation phone-home Lambda payload
  # so app templates referencing `nuon.install_stack.outputs.*` resolve
  # identically whether the customer applied via CFN or Terraform.
  phone_home_payload = merge({
    request_type    = "Create"
    phone_home_type = "aws"
    account_id      = data.aws_caller_identity.current.account_id
    region          = var.aws_region
    vpc_id          = var.vpc_id
    # Subnet lists are emitted as comma-joined strings to match the CFN
    # phone-home Lambda payload (CFN stack outputs are strings, joined with
    # `Fn::Join`). ctl-api's `updateinstallstackoutputs` decoder uses
    # `StringToSliceHookFunc(",")` to split them back into []string, so the
    # downstream stack outputs end up as proper lists either way. Sending an
    # actual JSON list here would land in postgres HSTORE as the string
    # "[subnet-x subnet-y]" (space-separated) and decode to an empty list.
    runner_subnet            = var.runner_subnet_id
    public_subnets           = join(",", var.public_subnet_ids)
    private_subnets          = join(",", var.private_subnet_ids)
    runner_security_group_id = aws_security_group.runner.id
    runner_iam_role_arn      = aws_iam_role.runner.arn
    runner_instance_profile  = aws_iam_instance_profile.runner.arn
    runner_asg_name          = local.runner_asg_name
    runner_log_group_name    = local.runner_log_group_name
    provision_iam_role_arn   = aws_iam_role.maintenance.arn
    maintenance_iam_role_arn = aws_iam_role.maintenance.arn
    deprovision_iam_role_arn = aws_iam_role.maintenance.arn
    break_glass_role_arns    = local.break_glass_role_arns
    custom_role_arns         = local.custom_role_arns
    install_inputs           = var.install_inputs
    custom_nested_stacks     = {}
    runner_enabled           = var.runner_enabled
  }, local.all_secret_arns)
}

resource "null_resource" "phone_home" {
  depends_on = [
    aws_security_group.runner,
    module.runner,
    aws_iam_role.runner,
    aws_iam_role.provision,
    aws_iam_role.maintenance,
    aws_iam_role_policy.maintenance,
    aws_iam_role.deprovision,
    aws_iam_role.break_glass,
    aws_iam_role.custom,
    aws_eks_access_entry.maintenance,
    kubernetes_role_binding_v1.maintenance,
    kubernetes_cluster_role_binding_v1.maintenance_cluster_read,
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -fS --http1.1 \
        --retry 5 --retry-all-errors --retry-delay 2 --max-time 30 \
        -X POST '${var.phone_home_url}' \
        -H 'Content-Type: application/json' \
        -d '${jsonencode(local.phone_home_payload)}'
    EOT
  }
}

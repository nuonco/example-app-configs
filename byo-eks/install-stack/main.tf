module "runner" {
  source = "./modules/runner"
  count  = var.runner_enabled ? 1 : 0

  prefix                       = local.prefix
  tags                         = local.tags
  vpc_id                       = var.vpc_id
  runner_subnet_id             = var.runner_subnet_id
  runner_security_group        = aws_security_group.runner.id
  runner_instance_profile_name = aws_iam_instance_profile.runner.name
  runner_api_url               = var.runner_api_url
  runner_id                    = var.runner_id
  nuon_install_id              = var.nuon_install_id
  instance_type                = var.runner_instance_type
}

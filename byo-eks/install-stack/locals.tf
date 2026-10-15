locals {
  prefix = var.nuon_install_id
  region = var.aws_region

  # Resolved inline policy documents — full JSON document takes precedence over
  # the permissions shorthand. Empty string means no inline policy on this role.
  provision_inline_policy = (
    var.provision_inline_policy_document != "" ? var.provision_inline_policy_document :
    length(var.provision_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = var.provision_permissions
        Resource = "*"
      }]
    }) : ""
  )
  deprovision_inline_policy = (
    var.deprovision_inline_policy_document != "" ? var.deprovision_inline_policy_document :
    length(var.deprovision_permissions) > 0 ? jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = var.deprovision_permissions
        Resource = "*"
      }]
    }) : ""
  )

  has_provision   = local.provision_inline_policy != "" || length(var.provision_managed_policy_arns) > 0
  has_deprovision = local.deprovision_inline_policy != "" || length(var.deprovision_managed_policy_arns) > 0

  enabled_break_glass_roles = { for k, v in var.break_glass_roles : k => v if v.enabled }
  enabled_custom_roles      = { for k, v in var.custom_roles : k => v if v.enabled }

  break_glass_inline_policies = {
    for k, v in local.enabled_break_glass_roles : k => (
      v.inline_policy_document != "" ? v.inline_policy_document :
      length(v.permissions) > 0 ? jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = v.permissions
          Resource = "*"
        }]
      }) : ""
    )
  }
  custom_inline_policies = {
    for k, v in local.enabled_custom_roles : k => (
      v.inline_policy_document != "" ? v.inline_policy_document :
      length(v.permissions) > 0 ? jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = v.permissions
          Resource = "*"
        }]
      }) : ""
    )
  }

  # These will be empty strings when the runner is disabled.
  runner_asg_name       = var.runner_enabled ? module.runner[0].asg_name : ""
  runner_log_group_name = var.runner_enabled ? module.runner[0].log_group_name : ""

  tags = {
    "install.nuon.co/id" = var.nuon_install_id
    "nuon_install_id"    = var.nuon_install_id
  }

  # Not a system: group. EKS rejects those on an access entry.
  maintenance_group = "nuon:install-maintenance"

  rbac_labels = {
    "install.nuon.co/id"           = var.nuon_install_id
    "app.kubernetes.io/managed-by" = "nuon-install-stack"
  }

  input_cluster_name = trimspace(lookup(var.install_inputs, "cluster_name", ""))
  input_namespaces = [
    for ns in split(",", coalesce(trimspace(lookup(var.install_inputs, "namespaces", "")), "sourdough,persimmon,tartar")) :
    trimspace(ns) if trimspace(ns) != ""
  ]

  eks_cluster_name = (
    var.eks_cluster_arn != "" ? one(regex("^arn:aws[a-z-]*:eks:[a-z0-9-]+:[0-9]{12}:cluster/(.+)$", var.eks_cluster_arn)) :
    local.input_cluster_name
  )
  eks_cluster = one(data.aws_eks_cluster.this)
  eks_auth    = one(data.aws_eks_cluster_auth.this)

  # Built from the cluster name so the maintenance role can DescribeCluster
  # before any data source has read the cluster.
  maintenance_oidc_issuer       = try(local.eks_cluster.identity[0].oidc[0].issuer, "")
  maintenance_oidc_provider_arn = local.maintenance_oidc_issuer == "" ? null : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${trimprefix(local.maintenance_oidc_issuer, "https://")}"

  maintenance_eks_read_resources = local.eks_cluster_name == "" ? [] : [
    "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${local.eks_cluster_name}",
    "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:nodegroup/${local.eks_cluster_name}/*",
    "arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:addon/${local.eks_cluster_name}/*",
  ]

  maintenance_namespace_names = length(var.maintenance_namespaces) > 0 ? var.maintenance_namespaces : local.input_namespaces

  # The access entry grants the group and no access policy. rbac.tf is the grant.
  grant_maintenance_rbac = local.eks_cluster_name != "" && length(local.maintenance_namespace_names) > 0

  declared_subnet_ids = distinct(concat(var.public_subnet_ids, var.private_subnet_ids, [var.runner_subnet_id]))
  stray_subnet_ids    = setsubtract(local.declared_subnet_ids, data.aws_subnets.vpc.ids)

  # An unassociated subnet inherits the VPC's main route table.
  runner_route_table_id = try(
    tolist(data.aws_route_tables.runner_explicit.ids)[0],
    tolist(data.aws_route_tables.vpc_main.ids)[0],
    "",
  )

  runner_default_routes = local.runner_route_table_id == "" ? [] : [
    for r in data.aws_route_table.runner[0].routes : r if r.cidr_block == "0.0.0.0/0"
  ]

  # The runner launches with no public IP, so an internet gateway target is not egress for it.
  runner_has_egress_route = anytrue([
    for r in local.runner_default_routes : !startswith(r.gateway_id == null ? "" : r.gateway_id, "igw-")
  ])
}

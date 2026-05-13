output "account" {
  value = {
    id     = data.aws_caller_identity.current.account_id
    region = var.region
  }
  description = "A map of AWS account attributes: id, region."
}

output "cluster" {
  value = {
    arn                        = module.eks.cluster_arn
    certificate_authority_data = module.eks.cluster_certificate_authority_data
    endpoint                   = module.eks.cluster_endpoint
    name                       = module.eks.cluster_name
    platform_version           = module.eks.cluster_platform_version
    status                     = module.eks.cluster_status
    oidc_issuer_url            = module.eks.cluster_oidc_issuer_url
    oidc_provider_arn          = module.eks.oidc_provider_arn
    oidc_provider              = module.eks.oidc_provider

    cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
    cluster_security_group_id         = module.eks.cluster_security_group_id

    node_groups            = module.eks.eks_managed_node_groups
    node_security_group_id = module.eks.node_security_group_id
  }
  description = "A map of EKS cluster attributes."
}

output "vpc" {
  value = {
    id   = data.aws_vpc.vpc.id
    arn  = data.aws_vpc.vpc.arn
    cidr = data.aws_vpc.vpc.cidr_block
    azs  = data.aws_availability_zones.available.names

    private_subnet_cidr_blocks = local.subnets.private.cidrs
    private_subnet_ids         = local.subnets.private.ids

    public_subnet_cidr_blocks = local.subnets.public.cidrs
    public_subnet_ids         = local.subnets.public.ids
    runner_subnet_id          = local.subnets.runner.ids[0]
    runner_subnet_cidr        = local.subnets.runner.cidrs[0]

    default_security_group_id = data.aws_security_group.default.id
  }
  description = "A map of vpc attributes."
}

output "namespaces" {
  value       = [for km in kubectl_manifest.namespaces : km.name]
  description = "A list of namespaces that were created on the cluster."
}

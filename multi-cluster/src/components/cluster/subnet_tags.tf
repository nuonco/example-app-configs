module "additional_subnet_tags" {
  source = "./subnet_tags"

  eks_cluster_name   = module.eks.cluster_name
  private_subnet_ids = local.subnets.private.ids
  public_subnet_ids  = local.subnets.public.ids
  depends_on         = [module.eks]
}

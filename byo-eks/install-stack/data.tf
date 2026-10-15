data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_subnets" "vpc" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_route_tables" "runner_explicit" {
  vpc_id = var.vpc_id

  filter {
    name   = "association.subnet-id"
    values = [var.runner_subnet_id]
  }
}

data "aws_route_tables" "vpc_main" {
  vpc_id = var.vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

data "aws_route_table" "runner" {
  count          = local.runner_route_table_id != "" ? 1 : 0
  route_table_id = local.runner_route_table_id
}

data "aws_eks_cluster" "this" {
  count = local.eks_cluster_name != "" ? 1 : 0
  name  = local.eks_cluster_name

  lifecycle {
    precondition {
      condition     = var.eks_cluster_arn == "" || strcontains(var.eks_cluster_arn, ":eks:${var.aws_region}:")
      error_message = "eks_cluster_arn must be in aws_region."
    }
    postcondition {
      condition     = (var.eks_cluster_arn == "" || self.arn == var.eks_cluster_arn) && strcontains(self.arn, ":eks:${var.aws_region}:")
      error_message = "The cluster must exist in aws_region and match eks_cluster_arn when that ARN is set."
    }
  }
}

data "aws_eks_cluster_auth" "this" {
  count = local.eks_cluster_name != "" ? 1 : 0
  name  = local.eks_cluster_name
}


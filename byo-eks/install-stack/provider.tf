provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      "install.nuon.co/id" = var.nuon_install_id
      "nuon_install_id"    = var.nuon_install_id
    }
  }
}

provider "kubernetes" {
  host = try(local.eks_cluster.endpoint, "https://127.0.0.1")
  cluster_ca_certificate = try(
    base64decode(local.eks_cluster.certificate_authority[0].data),
    null,
  )
  token = try(local.eks_auth.token, null)
}

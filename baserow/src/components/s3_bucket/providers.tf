provider "aws" {
  region = var.region

  alias = "current"

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

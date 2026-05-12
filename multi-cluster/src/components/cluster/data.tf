data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    visibility               = "public"
    "install.nuon.co/id"     = var.nuon_id
    "network.nuon.co/domain" = "public"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    visibility               = "private"
    "network.nuon.co/domain" = "internal"
    "install.nuon.co/id"     = var.nuon_id
  }
}

data "aws_subnets" "runner" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    visibility               = "private"
    "network.nuon.co/domain" = "runner"
    "install.nuon.co/id"     = var.nuon_id
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.key
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.key
}

data "aws_subnet" "runner" {
  for_each = toset(data.aws_subnets.runner.ids)
  id       = each.key
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.vpc.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Resolve the runner SG by inspecting the EC2 instance(s) actually running in
# the runner subnet. This is more reliable than a tag-based aws_security_groups
# lookup, which can return the wrong group if anything else in the install
# happens to be tagged with `network.nuon.co/domain = runner`.
data "aws_instances" "runner" {
  filter {
    name   = "subnet-id"
    values = data.aws_subnets.runner.ids
  }

  instance_state_names = ["pending", "running"]
}

data "aws_instance" "runner" {
  instance_id = data.aws_instances.runner.ids[0]
}

locals {
  subnets = {
    private = {
      ids   = data.aws_subnets.private.ids,
      cidrs = values(data.aws_subnet.private)[*].cidr_block,
    }
    public = {
      ids   = data.aws_subnets.public.ids,
      cidrs = values(data.aws_subnet.public)[*].cidr_block,
    }
    runner = {
      ids   = data.aws_subnets.runner.ids
      cidrs = values(data.aws_subnet.runner)[*].cidr_block
    }
  }
}

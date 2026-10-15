resource "aws_security_group" "runner" {
  name        = "${local.prefix}-runner-sg"
  description = "Nuon runner security group for ${local.prefix}"
  vpc_id      = var.vpc_id
  tags = merge(local.tags, {
    Name                     = "${local.prefix}-runner-sg"
    "network.nuon.co/domain" = "runner"
  })

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  lifecycle {
    precondition {
      condition     = length(local.stray_subnet_ids) == 0
      error_message = "Subnets do not belong to VPC ${var.vpc_id}: ${join(", ", local.stray_subnet_ids)}."
    }

    precondition {
      condition = length(local.stray_subnet_ids) > 0 || local.runner_has_egress_route
      error_message = length(local.runner_default_routes) == 0 ? (
        "Runner subnet ${var.runner_subnet_id} has no 0.0.0.0/0 route, so the runner cannot reach the Nuon API."
        ) : (
        "Runner subnet ${var.runner_subnet_id} routes 0.0.0.0/0 to an internet gateway only. The runner launches without a public IP, so that route gives it no egress; send the default route to a NAT gateway, a transit gateway, or an egress appliance."
      )
    }
  }
}

# Cluster security group, so the runner can reach the API server.
resource "aws_vpc_security_group_ingress_rule" "cluster_from_runner" {
  count = local.grant_maintenance_rbac ? 1 : 0

  security_group_id            = try(local.eks_cluster.vpc_config[0].cluster_security_group_id, null)
  referenced_security_group_id = aws_security_group.runner.id
  ip_protocol                  = "tcp"
  from_port                    = var.cluster_api_ingress_port
  to_port                      = var.cluster_api_ingress_port
  description                  = "nuon runner ${var.nuon_install_id}"
}

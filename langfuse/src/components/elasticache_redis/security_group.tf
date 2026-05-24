resource "aws_security_group" "redis" {
  vpc_id      = var.vpc_id
  name        = "elasticache-redis-${var.install_id}"
  description = "Allow Valkey/Redis traffic on port ${var.port} from within the VPC"

  tags = merge({
    Name = "elasticache-redis-${var.install_id}"
  }, local.tags)

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
}

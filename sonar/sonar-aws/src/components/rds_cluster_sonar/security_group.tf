resource "aws_security_group" "allow_psql" {
  vpc_id      = var.vpc_id
  name        = "allow_psql_${var.identifier}"
  description = "${var.identifier}: Allow PSQL traffic from within the VPC."

  tags = merge({
    Name       = "allow_psql_${var.identifier}"
    Identifier = var.identifier
  }, local.tags)

  ingress {
    from_port   = var.port
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    to_port     = var.port
    protocol    = "tcp"
  }
}

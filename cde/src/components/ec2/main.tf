locals {
  install_vscode_web  = var.install_vscode_web == "true"
  is_ubuntu           = var.os == "ubuntu-24.04"
  ssh_user            = local.is_ubuntu ? "ubuntu" : "ec2-user"
  sshd_service        = local.is_ubuntu ? "ssh" : "sshd"
  ami_id              = local.is_ubuntu ? data.aws_ami.ubuntu.id : data.aws_ami.al2023.id
  ssh_public_key      = replace(replace(replace(var.ssh_public_key, "&#43;", "+"), "&#47;", "/"), "&#61;", "=")
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_iam_role" "dev_env" {
  name = "cde-${var.install_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.dev_env.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0
  name  = "anthropic-api-key"
  role  = aws_iam_role.dev_env.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = "arn:aws:ssm:*:*:parameter/cde/${var.install_id}/anthropic-api-key"
    }]
  })
}

resource "aws_iam_instance_profile" "dev_env" {
  name = "cde-${var.install_id}"
  role = aws_iam_role.dev_env.name
}

resource "aws_security_group" "dev_env" {
  name   = "cde-${var.install_id}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  count  = local.install_vscode_web ? 1 : 0
  name   = "cde-alb-${var.install_id}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "vscode_from_alb" {
  count                    = local.install_vscode_web ? 1 : 0
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb[0].id
  security_group_id        = aws_security_group.dev_env.id
}

resource "aws_instance" "dev_env" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id_0
  iam_instance_profile   = aws_iam_instance_profile.dev_env.name
  vpc_security_group_ids = [aws_security_group.dev_env.id]

  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /home/${local.ssh_user}/.ssh
    echo "${local.ssh_public_key}" >> /home/${local.ssh_user}/.ssh/authorized_keys
    chmod 600 /home/${local.ssh_user}/.ssh/authorized_keys
    chown -R ${local.ssh_user}:${local.ssh_user} /home/${local.ssh_user}/.ssh
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart ${local.sshd_service}
  EOF

  tags = {
    Name = "cde-${var.install_id}"
  }
}

resource "aws_eip" "dev_env" {
  domain   = "vpc"
  instance = aws_instance.dev_env.id
}

resource "aws_ssm_parameter" "anthropic_api_key" {
  count = var.anthropic_api_key != "" ? 1 : 0
  name  = "/cde/${var.install_id}/anthropic-api-key"
  type  = "SecureString"
  value = var.anthropic_api_key
}

resource "aws_route53_record" "ssh" {
  zone_id = var.dns_zone_id
  name    = "dev.${var.dns_zone_name}"
  type    = "A"
  ttl     = 60
  records = [aws_eip.dev_env.public_ip]
}

resource "aws_lb" "vscode" {
  count              = local.install_vscode_web ? 1 : 0
  name               = substr("cde-${var.install_id}", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = [var.subnet_id_0, var.subnet_id_1]
}

resource "aws_acm_certificate" "vscode" {
  count             = local.install_vscode_web ? 1 : 0
  domain_name       = "ide.${var.dns_zone_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "vscode_cert_validation" {
  for_each = local.install_vscode_web ? {
    for dvo in aws_acm_certificate.vscode[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = var.dns_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "vscode" {
  count                   = local.install_vscode_web ? 1 : 0
  certificate_arn         = aws_acm_certificate.vscode[0].arn
  validation_record_fqdns = [for record in aws_route53_record.vscode_cert_validation : record.fqdn]
}

resource "aws_lb_target_group" "vscode" {
  count       = local.install_vscode_web ? 1 : 0
  name        = substr("cde-tg-${var.install_id}", 0, 32)
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group_attachment" "vscode" {
  count            = local.install_vscode_web ? 1 : 0
  target_group_arn = aws_lb_target_group.vscode[0].arn
  target_id        = aws_instance.dev_env.id
  port             = 8080
}

resource "aws_lb_listener" "vscode_https" {
  count             = local.install_vscode_web ? 1 : 0
  load_balancer_arn = aws_lb.vscode[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.vscode[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vscode[0].arn
  }
}

resource "aws_route53_record" "vscode" {
  count   = local.install_vscode_web ? 1 : 0
  zone_id = var.dns_zone_id
  name    = "ide.${var.dns_zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.vscode[0].dns_name
    zone_id                = aws_lb.vscode[0].zone_id
    evaluate_target_health = true
  }
}

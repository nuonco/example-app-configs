locals {
  registry = split("/", var.image_repository)[0]
}

resource "aws_security_group" "whoami" {
  name        = "whoami-sg-${var.install_id}"
  description = "Security group for whoami EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
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

# The image lives in the install's own ECR, so the instance needs pull creds.
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "whoami" {
  name               = "whoami-${var.install_id}"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.whoami.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "whoami" {
  name = "whoami-${var.install_id}"
  role = aws_iam_role.whoami.name
}

data "aws_ami" "amazon_linux_2023" {
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

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                   = "whoami-${var.install_id}"
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_linux_2023.id
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.whoami.id]
  iam_instance_profile   = aws_iam_instance_profile.whoami.name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    yum install -y docker
    systemctl start docker
    aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${local.registry}
    docker run -d --restart=always -p 80:80 ${var.image_repository}:${var.image_tag}
  EOF
}

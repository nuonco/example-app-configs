# Security group to allow HTTP traffic on port 80
resource "aws_security_group" "httpbin" {
  name        = "httpbin-sg-${var.install_id}"
  description = "Security group for httpbin EC2 instance"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP traffic on configured port
  ingress {
    description = "Allow HTTP from allowed IPs"
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ips]
  }
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

  name          = "httpbin-${var.install_id}"
  instance_type = var.instance_type
  ami           = data.aws_ami.amazon_linux_2023.id
  subnet_id     = var.subnet_id

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.httpbin.id]

  # Enable EBS encryption for root volume
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 8
    }
  ]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum install -y docker
    sudo systemctl start docker
    docker run \
      -e PORT=${var.http_port} \
      -e MAX_BODY_SIZE=${var.max_response_size} \
      -e MAX_DURATION=${var.max_duration}s \
      -e LOG_LEVEL=${var.log_level} \
      -p ${var.http_port}:${var.http_port} \
      mccutchen/go-httpbin:${var.httpbin_version}
  EOF
}

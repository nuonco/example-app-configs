# Security group to allow HTTP traffic on port 80
resource "aws_security_group" "httpbin" {
  name        = "httpbin-sg-${var.install_id}"
  description = "Security group for httpbin EC2 instance"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP traffic on port 80
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  instance_type = "t2.micro"
  ami           = data.aws_ami.amazon_linux_2023.id
  subnet_id     = var.subnet_id

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.httpbin.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum install -y docker
    sudo systemctl start docker
    docker run -e PORT=80 -p 80:80 mccutchen/go-httpbin:latest
  EOF
}

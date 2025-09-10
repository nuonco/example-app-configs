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

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name          = "httpbin-${var.install_id}"
  instance_type = "t2.micro"
  ami           = var.ami
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

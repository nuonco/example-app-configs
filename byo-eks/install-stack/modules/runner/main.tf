data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_cloudwatch_log_group" "runner" {
  name              = "/nuon/${var.nuon_install_id}/runner"
  retention_in_days = 30
  tags              = var.tags
}

locals {
  # Pinned to main: this stack is tightly coupled to the init script's tag
  # contract and IID auth flow. Do not version separately.
  runner_init_script_url = "https://raw.githubusercontent.com/nuonco/runner/refs/heads/main/scripts/aws/init-mng-v2.sh"

  # NAT GW + route table associations may not be ready when the instance
  # boots. Wait for outbound HTTPS to the init script host before running it,
  # so we don't burn the only user_data run on a transient connect timeout.
  user_data = <<-EOT
    #!/bin/bash
    set -e
    export RUNNER_AUTH_METHOD=iid
    for i in $(seq 1 30); do
      if curl -fsS --max-time 5 -o /dev/null https://raw.githubusercontent.com; then
        break
      fi
      echo "waiting for outbound egress... ($i/30)"
      sleep 10
    done
    curl -fsSL ${local.runner_init_script_url} | bash
  EOT

  runner_tags = merge(var.tags, {
    Name                = "${var.prefix}-runner"
    nuon_runner_id      = var.runner_id
    nuon_runner_api_url = var.runner_api_url
    nuon_install_id     = var.nuon_install_id
  })
}

resource "aws_launch_template" "runner" {
  name_prefix   = "${var.prefix}-runner-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    name = var.runner_instance_profile_name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.runner_security_group]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.runner_tags
  }
}

resource "aws_autoscaling_group" "runner" {
  name                = "${var.prefix}-runner-asg"
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [var.runner_subnet_id]

  launch_template {
    id      = aws_launch_template.runner.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  # ASGs ignore the launch template's tag_specifications when launching
  # instances — only ASG `tag` blocks with propagate_at_launch=true land on
  # the instance. The init script's `get_tag` lookups depend on these.
  dynamic "tag" {
    for_each = local.runner_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

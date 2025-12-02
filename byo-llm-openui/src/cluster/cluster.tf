# ECS Cluster with mixed capacity providers:
# - Fargate: default for ephemeral, on-demand workloads (builder task)
# - EC2: must be explicitly specified at service level for long-lived workloads (App, Web services)
# Note: AWS does not allow mixing FARGATE and EC2 capacity providers in default_capacity_provider_strategy

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ecs_instance" {
  name = "${local.prefix}-ecs-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${local.prefix}-ecs-instance"
  role = aws_iam_role.ecs_instance.name

  tags = local.tags
}

# Security group for EC2 instances
resource "aws_security_group" "ecs_instances" {
  name        = "${local.prefix}-ecs-instances"
  description = "Security group for ECS EC2 instances"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.prefix}-ecs-instances"
    }
  )
}

# Allow inbound traffic from ALB to ECS instances
resource "aws_security_group_rule" "ecs_from_alb" {
  count                    = local.alb_security_group_id != null ? 1 : 0
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = local.alb_security_group_id
  security_group_id        = aws_security_group.ecs_instances.id
  description              = "Allow traffic from ALB"
}

# Launch template for EC2 instances
resource "aws_launch_template" "ecs" {
  name                   = "${local.prefix}-ecs"
  image_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type          = local.ecs_instance_type
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }

  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${local.prefix} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true >> /etc/ecs/ecs.config
  EOF
  )

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.tags,
      {
        Name = "${local.prefix}-ecs-instance"
      }
    )
  }

  tags = local.tags
}

# Auto Scaling Group for EC2 instances
resource "aws_autoscaling_group" "ecs" {
  name                = "${local.prefix}-ecs"
  vpc_zone_identifier = local.private_subnet_ids
  min_size            = local.ecs_min_size
  max_size            = local.ecs_max_size
  desired_capacity    = local.ecs_desired_capacity

  health_check_type         = "EC2"
  health_check_grace_period = 300
  protect_from_scale_in     = true

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# ECS Cluster with both Fargate and EC2 capacity providers
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.9.0"

  cluster_name = local.prefix

  # Default capacity provider strategy
  # FARGATE/FARGATE_SPOT available for ephemeral workloads
  # EC2 capacity provider must be specified explicitly at service level
  # Note: Cannot mix FARGATE and EC2 capacity providers in default strategy
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 1
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }

  # EC2 capacity provider for long-lived services
  autoscaling_capacity_providers = {
    ec2 = {
      name                           = "${local.prefix}-ec2"
      auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 2
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 80
      }
    }
  }

  tags = local.tags
}

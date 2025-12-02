# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.prefix}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Allow traffic from ALB to Open WebUI"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.tags, { Name = "${local.prefix}-ecs-tasks" })
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for accessing Secrets Manager
resource "aws_iam_role_policy" "secrets_access" {
  name = "${local.prefix}-secrets-access"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.openai_secret_arn
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.prefix}/open-webui"
  retention_in_days = 30

  tags = local.tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = substr("open-webui-${local.prefix}", 0, 30)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name             = "open-webui"
      image            = "${var.app_image_repository}:${var.app_image_tag}"
      essential        = true
      workingDirectory = "/root/open-webui"
      command = [
        "/bin/bash",
        "-c",
        "/root/open-webui/backend/start.sh"
      ]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = var.openai_secret_arn
        }
      ]
      environment = [
        {
          name  = "WEBUI_AUTH"
          value = "false"
        },
        {
          name  = "HF_ENDPOINT"
          value = "https://hf-mirror.com"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "open-webui"
        }
      }
    }
  ])

  tags = local.tags
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = substr("open-webui-${local.prefix}", 0, 30)
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnets.private.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.app_target_group_arn
    container_name   = "open-webui"
    container_port   = 8080
  }

  tags = local.tags
}

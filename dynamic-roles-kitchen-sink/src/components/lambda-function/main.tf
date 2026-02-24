# Lambda Function with Container Image
resource "aws_lambda_function" "main" {
  function_name = var.function_name
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda_exec.arn

  timeout     = 30
  memory_size = 512

  environment {
    variables = {
      INSTALL_ID = var.install_id
    }
  }

  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "lambda_function"
  }
}

# Lambda Function URL for public access
resource "aws_lambda_function_url" "main" {
  function_name      = aws_lambda_function.main.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
    max_age       = 300
  }
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "${var.install_id}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "lambda_function"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 7

  tags = {
    "install.nuon.co/id"     = var.install_id
    "component.nuon.co/name" = "lambda_function"
  }
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  function_name = var.function_name
  handler       = "handler.handler"
  runtime       = "python3.13"

  create_package         = false
  local_existing_package = "${path.module}/handler.zip"

  cloudwatch_logs_retention_in_days = 3
  logging_log_group                 = "/aws/lambda/${var.install_id}/${var.function_name}"
}

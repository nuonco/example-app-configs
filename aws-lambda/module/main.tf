resource "aws_cloudformation_stack" "this" {
  name = var.stack_name

  template_url = var.template_url

  parameters   = var.parameters
  capabilities = var.capabilities

  on_failure         = var.on_failure
  timeout_in_minutes = var.timeout_in_minutes

  tags = {
    Name = var.stack_name
  }
}

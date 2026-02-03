output "stack_id" {
  value = aws_cloudformation_stack.this.id
}

output "stack_outputs" {
  value = aws_cloudformation_stack.this.outputs
}

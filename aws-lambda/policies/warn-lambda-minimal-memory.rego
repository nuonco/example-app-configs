package nuon

# Warn when Lambda function uses minimal memory allocation
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_lambda_function"
    resource.change.actions[_] in ["create", "update"]
    memory := resource.change.after.memory_size
    
    # Check if memory is minimal (128-512 MB)
    memory <= 512
    
    msg := sprintf(
        "Lambda function '%s' uses minimal memory (%d MB) - suitable for demos but consider increasing for production workloads",
        [resource.address, memory],
    )
}

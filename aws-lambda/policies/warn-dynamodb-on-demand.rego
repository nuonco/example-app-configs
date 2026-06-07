package nuon

# Warn when DynamoDB table uses on-demand billing mode
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_dynamodb_table"
    resource.change.actions[_] in ["create", "update"]
    billing_mode := resource.change.after.billing_mode
    billing_mode == "PAY_PER_REQUEST"
    msg := sprintf(
        "DynamoDB table '%s' uses on-demand billing (PAY_PER_REQUEST) - consider provisioned capacity for predictable workloads",
        [resource.address],
    )
}

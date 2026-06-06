package nuon

# Warn when security group allows public access (0.0.0.0/0)
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_security_group"
    resource.change.actions[_] in ["create", "update"]
    
    # Check for ingress rules with 0.0.0.0/0
    some ingress in resource.change.after.ingress
    "0.0.0.0/0" in ingress.cidr_blocks
    
    msg := sprintf(
        "Security group '%s' allows public access (0.0.0.0/0) - ensure this is intentional for public-facing services",
        [resource.address],
    )
}

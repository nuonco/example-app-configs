package nuon

# Deny security groups that allow unrestricted SSH access
deny contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_security_group"
    resource.change.actions[_] in ["create", "update"]
    some ingress in resource.change.after.ingress
    ingress.from_port == 22
    ingress.to_port == 22
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group '%s' must not allow SSH (port 22) from 0.0.0.0/0", [resource.address])
}

# Deny security groups that allow unrestricted RDP access
deny contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_security_group"
    resource.change.actions[_] in ["create", "update"]
    some ingress in resource.change.after.ingress
    ingress.from_port == 3389
    ingress.to_port == 3389
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group '%s' must not allow RDP (port 3389) from 0.0.0.0/0", [resource.address])
}

# Warn if security group allows all traffic from anywhere
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_security_group"
    resource.change.actions[_] in ["create", "update"]
    some ingress in resource.change.after.ingress
    ingress.from_port == 0
    ingress.to_port == 0
    ingress.protocol == "-1"
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group '%s' allows all traffic from 0.0.0.0/0 - consider restricting access", [resource.address])
}

# Warn if security group is missing a description
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_security_group"
    resource.change.actions[_] in ["create", "update"]
    not resource.change.after.description
    msg := sprintf("Security group '%s' should have a description for documentation", [resource.address])
}
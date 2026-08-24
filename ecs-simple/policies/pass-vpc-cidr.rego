package nuon

# Pass when VPC uses a proper private CIDR block (10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16)
pass contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_vpc"
    resource.change.actions[_] in ["create", "update"]
    cidr := resource.change.after.cidr_block
    
    # Check if CIDR starts with valid private range
    startswith(cidr, "10.")
    
    msg := sprintf(
        "VPC '%s' uses proper private CIDR block: %s",
        [resource.address, cidr],
    )
}

private_cidr(cidr) if {
    private_range := ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"][_]
    net.cidr_contains(private_range, cidr)
}

warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_vpc"
    resource.change.actions[_] in ["create", "update"]
    cidr := resource.change.after.cidr_block
    not private_cidr(cidr)

    msg := sprintf(
        "VPC '%s' uses CIDR block '%s' outside the RFC 1918 private address ranges",
        [resource.address, cidr],
    )
}

pass contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_vpc"
    resource.change.actions[_] in ["create", "update"]
    cidr := resource.change.after.cidr_block
    
    startswith(cidr, "172.")
    
    msg := sprintf(
        "VPC '%s' uses proper private CIDR block: %s",
        [resource.address, cidr],
    )
}

pass contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_vpc"
    resource.change.actions[_] in ["create", "update"]
    cidr := resource.change.after.cidr_block
    
    startswith(cidr, "192.168.")
    
    msg := sprintf(
        "VPC '%s' uses proper private CIDR block: %s",
        [resource.address, cidr],
    )
}

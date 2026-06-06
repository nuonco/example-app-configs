package nuon

# Pass when subnets are distributed across multiple availability zones
pass contains msg if {
    subnet_resources := [resource | 
        resource := input.plan.resource_changes[_]
        resource.type == "aws_subnet"
        resource.change.actions[_] in ["create", "update"]
    ]
    
    # Get unique availability zones
    azs := {az | 
        subnet := subnet_resources[_]
        az := subnet.change.after.availability_zone
    }
    
    # Check if we have multiple AZs
    count(azs) > 1
    
    msg := sprintf(
        "Subnets are distributed across %d availability zones for high availability",
        [count(azs)],
    )
}

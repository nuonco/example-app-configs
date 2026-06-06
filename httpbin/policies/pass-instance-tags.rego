package nuon

# Pass when EC2 instance has proper required tags
pass contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_instance"
    resource.change.actions[_] in ["create", "update"]
    tags := resource.change.after.tags
    
    # Check for required tags
    tags["Name"]
    tags["install.nuon.co/id"]
    tags["component.nuon.co/name"]
    
    msg := sprintf(
        "EC2 instance '%s' has all required tags (Name, install ID, component name)",
        [resource.address],
    )
}

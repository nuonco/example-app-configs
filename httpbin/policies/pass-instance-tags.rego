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

required_tags := {"Name", "install.nuon.co/id", "component.nuon.co/name"}

warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_instance"
    resource.change.actions[_] in ["create", "update"]
    tags := object.get(resource.change.after, "tags", {})
    missing_tags := {tag |
        required_tags[tag]
        object.get(tags, tag, "") == ""
    }
    count(missing_tags) > 0

    msg := sprintf(
        "EC2 instance '%s' is missing required tags: %s",
        [resource.address, concat(", ", sort(missing_tags))],
    )
}

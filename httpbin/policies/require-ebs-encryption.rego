package nuon

# Deny EC2 instances with unencrypted root volumes
deny contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_instance"
    resource.change.actions[_] in ["create", "update"]
    not resource.change.after.root_block_device[_].encrypted
    msg := sprintf("EC2 instance '%s' must have encrypted root volume", [resource.address])
}

# Deny creation of unencrypted EBS volumes
deny contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_ebs_volume"
    resource.change.actions[_] in ["create", "update"]
    not resource.change.after.encrypted
    msg := sprintf("EBS volume '%s' must be encrypted", [resource.address])
}

# Warn if encryption is enabled but no KMS key is specified
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_ebs_volume"
    resource.change.actions[_] in ["create", "update"]
    resource.change.after.encrypted == true
    not resource.change.after.kms_key_id
    msg := sprintf("EBS volume '%s' is encrypted but not using a custom KMS key", [resource.address])
}
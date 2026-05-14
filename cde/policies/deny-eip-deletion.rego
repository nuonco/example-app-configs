package nuon

instance_being_deleted if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_instance"
	resource.change.actions[_] == "delete"
}

deny contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_eip"
	resource.change.actions[_] == "delete"
	not instance_being_deleted
	msg := sprintf("Elastic IP '%s' cannot be deleted independently; DNS stability requires it to remain bound to the instance", [resource.address])
}

package nuon

warn contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_instance"
	instance_type := resource.change.after.instance_type
	not endswith(instance_type, ".nano")
	not endswith(instance_type, ".micro")
	not endswith(instance_type, ".small")
	not endswith(instance_type, ".medium")
	msg := sprintf("Instance type '%s' is larger than medium; verify this cost is intentional", [instance_type])
}

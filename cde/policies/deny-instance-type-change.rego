package nuon

deny contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_instance"
	resource.change.actions[_] == "update"
	resource.change.before.instance_type != resource.change.after.instance_type
	msg := sprintf("In-place instance type change from '%s' to '%s' will cause downtime; use the stop-dev-env action first, then redeploy", [resource.change.before.instance_type, resource.change.after.instance_type])
}

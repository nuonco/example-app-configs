package nuon

rds_types := {"aws_db_instance", "aws_rds_cluster", "awscc_rds_db_cluster"}

planned_change(resource) if {
	resource.mode == "managed"
	resource.change.actions[_] == "create"
}

planned_change(resource) if {
	resource.mode == "managed"
	resource.change.actions[_] == "update"
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type in rds_types
	object.get(resource.change.after, "storage_encrypted", false) != true
	msg := sprintf(
		"RDS resource '%s' does not have storage encryption enabled",
		[resource.address],
	)
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type in rds_types
	object.get(resource.change.after, "publicly_accessible", false) == true
	msg := sprintf(
		"RDS resource '%s' is publicly accessible — keep the database private to the VPC",
		[resource.address],
	)
}

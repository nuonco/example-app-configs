package nuon

rds_types := {"aws_db_instance", "aws_rds_cluster", "awscc_rds_db_cluster"}

planned_update(resource) if {
	resource.mode == "managed"
	resource.change.actions[_] == "update"
}

deny contains msg if {
	some resource in input.plan.resource_changes
	planned_update(resource)
	resource.type in rds_types
	object.get(resource.change.after, "publicly_accessible", false) == true
	msg := sprintf(
		"RDS resource '%s' must not be publicly accessible",
		[resource.address],
	)
}

deny contains msg if {
	some resource in input.plan.resource_changes
	resource.mode == "managed"
	resource.change.actions[_] == "create"
	resource.type in rds_types
	object.get(resource.change.after, "publicly_accessible", false) == true
	msg := sprintf(
		"RDS resource '%s' must not be publicly accessible",
		[resource.address],
	)
}

deny contains msg if {
	some resource in input.plan.resource_changes
	planned_update(resource)
	resource.type in rds_types
	before := resource.change.before
	after := resource.change.after
	object.get(before, "backup_retention_period", 0) > 0
	object.get(after, "backup_retention_period", 0) == 0
	msg := sprintf(
		"RDS resource '%s' must not disable backup retention (backup_retention_period -> 0)",
		[resource.address],
	)
}

deny contains msg if {
	some resource in input.plan.resource_changes
	planned_update(resource)
	resource.type == "aws_db_instance"
	before := resource.change.before
	after := resource.change.after
	object.get(before, "allocated_storage", 0) > object.get(after, "allocated_storage", 0)
	msg := sprintf(
		"RDS instance '%s' storage shrink (%v -> %v GB) is not allowed; AWS forces replacement",
		[resource.address, before.allocated_storage, after.allocated_storage],
	)
}

package nuon

rds_types := {"aws_db_instance", "aws_rds_cluster", "awscc_rds_db_cluster"}

is_replace(actions) if {
	count(actions) == 2
	actions[0] == "delete"
	actions[1] == "create"
}

is_replace(actions) if {
	count(actions) == 2
	actions[0] == "create"
	actions[1] == "delete"
}

warn contains msg if {
	some resource in input.plan.resource_changes
	resource.type in rds_types
	resource.change.actions[_] == "delete"
	not is_replace(resource.change.actions)
	msg := sprintf(
		"RDS resource '%s' will be deleted — data loss risk. Deprovision also deletes; use AWS deletion_protection for prod, not a hard OPA deny",
		[resource.address],
	)
}

warn contains msg if {
	some resource in input.plan.resource_changes
	resource.type in rds_types
	is_replace(resource.change.actions)
	msg := sprintf(
		"RDS resource '%s' will be replaced — review carefully for data loss or downtime",
		[resource.address],
	)
}

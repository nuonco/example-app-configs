# the database component creates a DynamoDB table; on first deploy the "create" action is allowed, but changing the billing_mode input and redeploying produces an "update" action which intentionally triggers the following policy:

package nuon

deny contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_dynamodb_table"
	action := resource.change.actions[_]
	action == "update"
	msg := sprintf("Database modification denied: changes to '%s' could cause downtime", [resource.address])
}

deny contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_dynamodb_table"
	action := resource.change.actions[_]
	action == "delete"
	msg := sprintf("Database deletion denied: removing '%s' would cause data loss", [resource.address])
}

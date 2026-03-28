# the s3-bucket component creates an aws_s3_bucket resource, which intentionally triggers the following policy:

package nuon

deny contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_s3_bucket"
	resource.change.actions[_] == "create"
	msg := sprintf("S3 bucket creation is not allowed (%s)", [resource.address])
}

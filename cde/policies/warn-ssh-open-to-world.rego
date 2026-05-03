package nuon

warn contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_security_group"
	ingress := resource.change.after.ingress[_]
	ingress.from_port <= 22
	ingress.to_port >= 22
	ingress.cidr_blocks[_] == "0.0.0.0/0"
	msg := sprintf("Security group '%s' allows SSH (port 22) from 0.0.0.0/0", [resource.address])
}

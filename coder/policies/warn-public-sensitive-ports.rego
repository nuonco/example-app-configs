package nuon

sensitive_ports := {22, 23, 1433, 2375, 2376, 3306, 5432, 5984, 6379, 9200, 11211, 27017, 3389}
all_protocol_values := {"-1", "all"}

planned_change(resource) if {
	resource.mode == "managed"
	resource.change.actions[_] == "create"
}

planned_change(resource) if {
	resource.mode == "managed"
	resource.change.actions[_] == "update"
}

public_source(rule) if {
	rule.cidr_blocks[_] == "0.0.0.0/0"
}

public_source(rule) if {
	rule.ipv6_cidr_blocks[_] == "::/0"
}

public_source(rule) if {
	rule.cidr_ipv4 == "0.0.0.0/0"
}

public_source(rule) if {
	rule.cidr_ipv6 == "::/0"
}

all_protocols(rule) if {
	object.get(rule, "protocol", "") in all_protocol_values
}

all_protocols(rule) if {
	object.get(rule, "ip_protocol", "") in all_protocol_values
}

sensitive_port_exposed(rule) if {
	some port in sensitive_ports
	rule.from_port <= port
	rule.to_port >= port
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type == "aws_security_group_rule"
	rule := resource.change.after
	rule.type == "ingress"
	public_source(rule)
	all_protocols(rule)
	msg := sprintf("%s exposes every protocol to the internet", [resource.address])
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type == "aws_security_group_rule"
	rule := resource.change.after
	rule.type == "ingress"
	public_source(rule)
	sensitive_port_exposed(rule)
	msg := sprintf("%s exposes a sensitive port range to the internet", [resource.address])
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type == "aws_vpc_security_group_ingress_rule"
	rule := resource.change.after
	public_source(rule)
	all_protocols(rule)
	msg := sprintf("%s exposes every protocol to the internet", [resource.address])
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type == "aws_vpc_security_group_ingress_rule"
	rule := resource.change.after
	public_source(rule)
	sensitive_port_exposed(rule)
	msg := sprintf("%s exposes a sensitive port range to the internet", [resource.address])
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type == "aws_security_group"
	some rule in object.get(resource.change.after, "ingress", [])
	public_source(rule)
	all_protocols(rule)
	msg := sprintf("%s exposes every protocol to the internet", [resource.address])
}

warn contains msg if {
	some resource in input.plan.resource_changes
	planned_change(resource)
	resource.type == "aws_security_group"
	some rule in object.get(resource.change.after, "ingress", [])
	public_source(rule)
	sensitive_port_exposed(rule)
	msg := sprintf("%s exposes a sensitive port range to the internet", [resource.address])
}

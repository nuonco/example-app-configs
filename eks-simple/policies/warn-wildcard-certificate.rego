package nuon

# Warn when ACM certificate uses wildcard domain
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_acm_certificate"
    resource.change.actions[_] in ["create", "update"]
    domain := resource.change.after.domain_name
    startswith(domain, "*.")
    msg := sprintf(
        "Certificate '%s' uses wildcard domain '%s' - consider using specific domain names for production",
        [resource.address, domain],
    )
}

package nuon

# Warn when EKS cluster has public endpoint access enabled
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_eks_cluster"
    resource.change.actions[_] in ["create", "update"]
    resource.change.after.vpc_config[_].endpoint_public_access == true
    msg := sprintf(
        "EKS cluster '%s' has public endpoint access enabled - ensure this is intentional for demo/development environments",
        [resource.address],
    )
}

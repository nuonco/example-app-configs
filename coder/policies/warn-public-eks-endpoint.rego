package nuon

# Warn when any EKS cluster has public endpoint access enabled.
# cluster_endpoint_public_access = true is set in sandbox.tfvars.
# Nuon docs: https://docs.nuon.co/concepts/policies#policies
warn contains msg if {
    some resource in input.plan.resource_changes
    resource.type == "aws_eks_cluster"
    resource.change.actions[_] in ["create", "update"]
    resource.change.after.vpc_config[_].endpoint_public_access == true
    msg := sprintf(
        "EKS cluster '%s' has public endpoint access enabled — ensure this is intentional e.g., an example app or for demonstrating policies in Nuon",
        [resource.address],
    )
}

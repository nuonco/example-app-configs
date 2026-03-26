# the sandbox.tfvars file has cluster_endpoint_public_access = true which intentionally triggers the following policy:

package nuon

warn contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_eks_cluster"
	resource.mode == "managed"
	vpc := resource.change.after.vpc_config[_]
	vpc.endpoint_public_access == true
	msg := sprintf("EKS cluster '%s' has public endpoint access enabled", [resource.address])
}

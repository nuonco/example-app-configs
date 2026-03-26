# the sandbox (https://github.com/nuonco/aws-eks-auto-sandbox) creates EKS access entries for the runner roles (provision, maintenance, deprovision); adding any non-runner IAM principal would intentionally trigger the following policy:

package nuon

runner_role_patterns := ["provision", "maintenance", "deprovision"]

is_runner_role(principal_arn) if {
	pattern := runner_role_patterns[_]
	contains(principal_arn, pattern)
}

deny contains msg if {
	resource := input.plan.resource_changes[_]
	resource.type == "aws_eks_access_entry"
	resource.change.actions[_] == "create"
	principal := resource.change.after.principal_arn
	not is_runner_role(principal)
	msg := sprintf("EKS access entry for non-runner principal '%s' is not allowed", [principal])
}

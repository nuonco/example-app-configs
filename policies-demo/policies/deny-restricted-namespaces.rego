# the whoami-kube-system component deploys a manifest to the kube-system namespace, which intentionally triggers the following policy: 

package nuon

restricted_namespaces := {"default", "kube-system", "kube-public"}

deny contains msg if {
	ns := input.review.object.metadata.namespace
	restricted_namespaces[ns]
	msg := sprintf("Deployment to namespace '%s' is restricted (%s)", [ns, input.review.object.metadata.name])
}

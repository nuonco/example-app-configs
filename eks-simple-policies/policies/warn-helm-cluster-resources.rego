package nuon

deny contains msg if {
  kind := input.review.kind.kind
  kind != ""
  cluster_kinds[kind]
  name := object.get(input.review.object.metadata, "name", "")
  namespace := object.get(input.review.object.metadata, "namespace", "")
  msg := format_cluster_msg(kind, name, namespace)
}

cluster_kinds := {
  "CustomResourceDefinition",
  "Namespace",
  "ClusterRole",
  "ClusterRoleBinding",
  "MutatingWebhookConfiguration",
  "ValidatingWebhookConfiguration",
  "APIService",
  "PriorityClass",
  "StorageClass",
  "ClusterIssuer",
  "Node",
  "RuntimeClass"
}

format_cluster_msg(kind, name, namespace) := msg if {
  name != ""
  namespace != ""
  msg := sprintf("cluster-level resource %s/%s/%s detected in helm chart", [kind, namespace, name])
}

format_cluster_msg(kind, name, namespace) := msg if {
  name != ""
  namespace == ""
  msg := sprintf("cluster-level resource %s/%s detected in helm chart", [kind, name])
}

format_cluster_msg(kind, name, namespace) := msg if {
  name == ""
  namespace != ""
  msg := sprintf("cluster-level resource %s/%s detected in helm chart", [kind, namespace])
}

format_cluster_msg(kind, name, namespace) := msg if {
  name == ""
  namespace == ""
  msg := sprintf("cluster-level resource %s detected in helm chart", [kind])
}

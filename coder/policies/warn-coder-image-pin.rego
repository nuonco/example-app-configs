package nuon

containers_from(obj) := obj.spec.containers if {
	input.review.kind.kind == "Pod"
}

containers_from(obj) := obj.spec.template.spec.containers if {
	input.review.kind.kind in {"Deployment", "StatefulSet", "DaemonSet", "ReplicaSet"}
}

image_tag(image) := tag if {
	parts := split(image, ":")
	count(parts) > 1
	not contains(image, "@sha256:")
	tag := parts[count(parts) - 1]
}

unpinned(image) if {
	endswith(image, ":latest")
}

unpinned(image) if {
	not contains(image, ":")
	not contains(image, "@")
}

unpinned(image) if {
	tag := image_tag(image)
	tag == "latest"
}

warn contains msg if {
	some container in containers_from(input.review.object)
	unpinned(container.image)
	msg := sprintf(
		"Container '%s' uses unpinned image '%s' — set an exact coder_image_tag (not latest)",
		[container.name, container.image],
	)
}

package nuon

deny = [{"msg": "Service of type LoadBalancer is not allowed"} |
	input.review.object.spec.type == "LoadBalancer"
]

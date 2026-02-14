package nuon

deny = [{"msg": "ALB with internet-facing scheme is not allowed"} |
	input.review.object.metadata.annotations["alb.ingress.kubernetes.io/scheme"] == "internet-facing"
]

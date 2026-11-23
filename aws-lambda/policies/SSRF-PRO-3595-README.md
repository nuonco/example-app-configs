# PRO-3595 — OPA `http.send` SSRF PoC

Proof-of-concept policies for [PRO-3595](https://linear.app/nuonco/issue/PRO-3595):
an app config can make the **control plane** reach IMDS and private addresses via
OPA's `http.send`. These validate the fix on `fd/pro-3597/opa/restrict-httpsend`.

> Defensive use only. These demos **read responses back into the policy result
> locally** (so you can see the leak in `nuon` output / test logs). They do not
> exfiltrate anything to an external host. Run them only against infrastructure
> you own — a local stack or a loopback listener.

## The vulnerability

Policies are authored in an app config but evaluated on the **control-plane
worker**, not in the customer cloud. On `main`, OPA runs with the default
capability set, so `http.send` is enabled. A policy author can therefore:

- drive the full IMDSv2 token dance (`PUT /latest/api/token`, then GET creds),
- set arbitrary headers (GCP `Metadata-Flavor`, Azure `Metadata: true`),
- hit any internal/RFC-1918/loopback/cluster host the worker can route to,
- and **read the response body back** through the deny/finding message.

There are two distinct evaluation paths, and the fix must close both:

| Path | Package | Code |
| --- | --- | --- |
| Legacy | `package nuon` | `evaluate_single_policy.go` `evaluateRule` |
| Named checks | `package nuon.checks` | `pkg/policies/opa` `Policy.Evaluate` |

## The files

| File | Package | Demonstrates |
| --- | --- | --- |
| `ssrf-imds-aws-legacy.rego` | `nuon` | Full AWS IMDSv2 → role → STS creds, legacy path |
| `ssrf-imds-named-check.rego` | `nuon.checks` | Same AWS attack, named-checks path |
| `ssrf-imds-gcp-azure.rego` | `nuon` | GCP + Azure metadata token endpoints (header-gated) |
| `ssrf-internal-service.rego` | `nuon` | Arbitrary internal/loopback target (safe repro) |

## Expected results

**On `main` (vulnerable):** policies compile and evaluate; the deny/finding
message contains the recovered IMDS token, role name, and/or STS credentials
(or the internal response body).

**On `fd/pro-3597/opa/restrict-httpsend` (fixed):** config validation and
compilation **fail** with `undefined function http.send` — `http.send` and
`net.lookup_ip_addr` are stripped from `opa.Capabilities()` and `AllowNet` is
set to `[]`. The policy can never run.

## How to test

### 1. Unit-level (fastest — exercises both paths directly)

The fix already ships regression tests mirroring these PoCs:

```bash
cd ~/nuon/nuon
go test ./pkg/policies/opa/...            # Parse rejects http.send on both paths
go test ./pkg/config/validate/...         # ValidateOPAPolicy rejects network builtins
```

To watch the *vulnerable* behavior, check out `main` and point a quick Rego
harness (same `rego.New(...)` options as `evaluateRule`) at a loopback
`httptest` server — it will receive the `PUT` with
`X-aws-ec2-metadata-token-ttl-seconds` and the deny result will contain the body.

### 2. Config validation (end to end, no cloud needed)

Wire a PoC into `policies.toml` and sync the app config:

```toml
# aws-lambda/policies.toml  — uncomment ONE to test; remove after testing.
# [[policy]]
# type     = "sandbox"
# engine   = "opa"
# contents = "./policies/ssrf-imds-aws-legacy.rego"
```

- On the fix branch, `nuon` config validation rejects the sync:
  `undefined function http.send`.
- On `main`, it validates (no builtin rejection) and the policy runs at
  evaluation time against the worker's network.

> Leave `policies.toml` unchanged by default — committing a PoC entry would make
> this example app fail validation on the fix branch (which is the point, but it
> breaks the example for everyone else).

### 3. Safe internal repro

On the control-plane worker (local stack), run `python3 -m http.server 8080`,
leave `ssrf-internal-service.rego` pointed at `http://127.0.0.1:8080/`, and
evaluate on `main`. The listener logs the request and the deny message echoes
the response body — SSRF confirmed without touching real metadata.

## Acceptance criteria covered

- [x] A policy using `http.send` fails validation + evaluation on **both** paths
- [x] IMDSv2 (AWS), GCP, and Azure metadata targets documented as PoCs
- [x] Internal/loopback reachability demonstrated with a safe target
- Remaining ticket items (#2–#6, `publicnet` `168.63.129.16`, Terraform
  vendoring, action-step decision) are out of scope for the OPA fix.

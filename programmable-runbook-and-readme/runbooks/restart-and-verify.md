# restart-and-verify

> [!NOTE]
> The on-call restart, encoded. Rolls the whoami deployment for install
> `{{ .nuon.install.id }}` and confirms it's serving traffic again — one
> recorded click instead of finding the right cluster and running
> `kubectl rollout restart` by hand at 3 a.m.

## What it does

1. **restart** — runs the existing **deployments_restart** action
   (`kubectl rollout restart`) to roll the `whoami` Deployment.
2. **verify** — curls the public endpoint, retrying until it returns a healthy
   status, so the run only succeeds once the service is actually back.

## Target

{{ if and .nuon.sandbox.populated .nuon.sandbox.outputs }}
{{ $sub := "whoami" }}{{ with .nuon.inputs }}{{ with .inputs }}{{ with .subdomain }}{{ $sub = . }}{{ end }}{{ end }}{{ end }}

<nuon-group gap="8" align="center">
  <nuon-badge theme="info" variant="code">GET</nuon-badge>
  <nuon-badge theme="default" variant="code">https://{{ $sub }}.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}/</nuon-badge>
</nuon-group>

{{ else }}

The target URL is available once the sandbox is deployed.

{{ end }}

## Current component status

{{ if .nuon.components }}

| Component | Status |
|-----------|--------|
{{- range $name, $component := .nuon.components }}
| `{{ $name }}` | `{{ $component.status }}` |
{{- end }}

{{ else }}

No components are active in this install yet.

{{ end }}

> [!TIP]
> Safe to re-run any time — it's the same recorded procedure across every
> customer install.

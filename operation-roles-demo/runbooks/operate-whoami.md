# operate-whoami

> [!NOTE]
> Inspect, restart, and verify the `whoami` deployment for install
> `{{ .nuon.install.id }}`. Each step runs under its own per-operation IAM
> role — the same roles the components and actions use — so the runbook
> demonstrates the runbook step `role` parameter end to end.

## What it does

1. **status** — `kubectl get deployments -n whoami` under
   `{{.nuon.install.id}}-deployments-status-trigger` (EKS **View**, scoped to
   the `whoami` namespace). Read-only.
2. **restart** — `kubectl rollout restart deployment whoami` under
   `{{.nuon.install.id}}-deployment-restart-trigger` (EKS **Cluster Admin**).
   Write.
3. **verify** — curls the public endpoint, retrying until it returns healthy,
   so the run only succeeds once the service is back. No kubectl access needed,
   so this step uses the runner's default role.

## The role parameter

A runbook `[[steps]]` block accepts a `role` field that names the IAM role the
runner assumes for that inline step. It is the step-level analogue of the `role`
field on actions and the `[[operation_roles]]` blocks on components. The two
roles referenced here are already provisioned by this app and wired to EKS
access entries in `sandbox.tfvars`, so no extra setup is required.

| Step | Role | EKS access |
|------|------|------------|
| `status` | `{{.nuon.install.id}}-deployments-status-trigger` | View (namespace `whoami`) |
| `restart` | `{{.nuon.install.id}}-deployment-restart-trigger` | Cluster Admin |
| `verify` | _runner default_ | none |

## Target

{{ if and .nuon.sandbox.populated .nuon.sandbox.outputs }}

<nuon-group gap="8" align="center">
  <nuon-badge theme="info" variant="code">GET</nuon-badge>
  <nuon-badge theme="default" variant="code">https://{{.nuon.inputs.inputs.sub_domain}}.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}/</nuon-badge>
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
> Safe to re-run any time. The `status` step cannot mutate the cluster — its
> role only grants the EKS View policy — so it doubles as a least-privilege
> health check.

<center>
<h1>Dynamic Role Kitchen Sink</h1>
This app demonstrates the full range of dynamic operation role assignment in Nuon — every component, action, and sandbox operation runs under a dedicated least-privilege IAM role.

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

</center>

## What This Demonstrates

Nuon resolves which IAM role to use for each operation using a precedence chain:

1. **Runtime override** — `--role` flag or dashboard selection
2. **Entity role** — inline `operation_roles` in component/action configs ← used here
3. **Matrix rules** — app-wide rules in `operation_roles.toml` ← also present as a fallback
4. **Default role** — fallback from `permissions.toml`

This app uses **entity roles** (inline) as the primary assignment so each config file is self-describing. The `operation_roles.toml` matrix remains as a fallback using shared custom roles.

---

## Role Map

### Sandbox (`sandbox.toml`)

| Operation | Role |
|-----------|------|
| `provision` | `{{.nuon.install.id}}-sandbox-provision` |
| `reprovision` | `{{.nuon.install.id}}-sandbox-maintenance` |
| `deprovision` | `{{.nuon.install.id}}-sandbox-deprovision` |

Roles are defined in `permissions/sandbox-provision.toml`, `sandbox-maintenance.toml`, `sandbox-deprovision.toml`.

### Components

| Component | Operation | Role |
|-----------|-----------|------|
| `whoami` | `deploy` | `{{.nuon.install.id}}-whoami-deploy` |
| `whoami` | `teardown` | `{{.nuon.install.id}}-whoami-teardown` |
| `certificate` | `deploy` | `{{.nuon.install.id}}-certificate-deploy` |
| `certificate` | `teardown` | `{{.nuon.install.id}}-certificate-teardown` |
| `application_load_balancer` | `deploy` | `{{.nuon.install.id}}-alb-deploy` |
| `application_load_balancer` | `teardown` | `{{.nuon.install.id}}-alb-teardown` |

Roles are defined in `permissions/whoami-deploy.toml`, `certificate-deploy.toml`, etc.
Each component carries its own `[[operation_roles]]` blocks inline.

### Actions

| Action | Role |
|--------|------|
| `certificate_status` | `{{.nuon.install.id}}-certificate-status-trigger` |
| `deployments_status` | `{{.nuon.install.id}}-deployments-status-trigger` |
| `deployment_restart` | `{{.nuon.install.id}}-deployment-restart-trigger` |
| `alb` | `{{.nuon.install.id}}-alb-trigger` |
| `alb_healthcheck` | `{{.nuon.install.id}}-alb-healthcheck-trigger` |
| `simple_demonstration` | `{{.nuon.install.id}}-simple-demonstration-trigger` |

Roles are defined in `permissions/*-trigger.toml`.
Each action carries its `role` field inline.

### Matrix Fallback (`operation_roles.toml`)

The matrix covers the same principals using shared `custom-1/2/3` roles. Because entity roles take precedence, the matrix only fires when no inline role is present — useful during development or when adding new components before their dedicated roles are created.

---

## App URL

[https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

```bash
curl https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
```

---

### Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

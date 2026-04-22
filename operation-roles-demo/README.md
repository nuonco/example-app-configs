<center>
<h1>Operation Roles Demo</h1>
Every sandbox, component, and action operation runs under a dedicated per-operation IAM role.

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

</center>

## What This Demonstrates

Operation roles let you assign a specific IAM role to each individual operation the Nuon runner performs. Instead of one all-purpose maintenance role, each component/action workflow gets its own role scoped to the AWS APIs it actually calls.

The runner selects a role using this precedence chain:

| Priority | Source | Scope |
|----------|--------|-------|
| 1 (highest) | Runtime override (`--role` flag / dashboard) | Any operation |
| 2 | Entity role (inline `[[operation_roles]]` or `role` field) | Single entity |
| 3 | Matrix rule (`operation_roles.toml`) | App-wide |
| 4 (lowest) | Default role (`permissions/provision.toml`, etc.) | App-wide |

This app uses **entity roles** (inline `[[operation_roles]]` blocks on components, `role` field on actions) for every non-sandbox operation. The matrix-rule mechanism (priority 3) is supported by Nuon but is not used here — see the Nuon docs for its syntax.

> **Note:** Sandbox operations use the default provision/maintenance/deprovision roles (not custom operation roles) because the sandbox terraform creates the EKS cluster and needs kubectl access during the same apply. Custom roles would lack EKS access entries until the cluster grants them — a bootstrapping problem.

### IAM vs. EKS access entries

Two layers of authorization are at play:

- **AWS IAM** — the policies attached to each custom role in `permissions/*.toml` control which AWS APIs the role can call (e.g., `eks:DescribeCluster`, `acm:RequestCertificate`, `route53:*`).
- **EKS access entries** — once the role can call `eks:DescribeCluster` and assume kubectl, Kubernetes RBAC is controlled separately via `additional_access_entry` in `sandbox.tfvars`. That block maps each custom role ARN to an EKS policy (e.g., `AmazonEKSClusterAdminPolicy` cluster-wide, or `AmazonEKSViewPolicy` scoped to the `whoami` namespace for the read-only action).

The custom role IAM policies are intentionally thin on EKS actions (just `DescribeCluster`) because the meaningful kubectl authority is granted at the EKS layer, not the IAM layer.

---

## Role Map

### Sandbox (`sandbox.toml`)

Uses default roles from `permissions/provision.toml`, `maintenance.toml`, and `deprovision.toml`.

### Components

| Component | Operation | Role | Permission Boundary |
|-----------|-----------|------|---------------------|
| `whoami` (helm) | `deploy` | `{{.nuon.install.id}}-whoami-deploy` | `provision_boundary.json` |
| `whoami` (helm) | `teardown` | `{{.nuon.install.id}}-whoami-teardown` | `deprovision_boundary.json` |
| `alb` (helm) | `deploy` | `{{.nuon.install.id}}-alb-deploy` | `provision_boundary.json` |
| `alb` (helm) | `teardown` | `{{.nuon.install.id}}-alb-teardown` | `deprovision_boundary.json` |
| `certificate` (terraform) | `deploy` | `{{.nuon.install.id}}-certificate-deploy` | `provision_boundary.json` |
| `certificate` (terraform) | `teardown` | `{{.nuon.install.id}}-certificate-teardown` | `deprovision_boundary.json` |

### Actions

| Action | Role | Permission Boundary |
|--------|------|---------------------|
| `deployments_status` (read-only) | `{{.nuon.install.id}}-deployments-status-trigger` | `maintenance_boundary.json` |
| `deployment_restart` (write) | `{{.nuon.install.id}}-deployment-restart-trigger` | `maintenance_boundary.json` |

Note the contrast: `deployments_status` only needs `eks:DescribeCluster` while `deployment_restart` also needs EKS edit access via its cluster access entry.

---

## File Structure

```
.
├── runner.toml                    # Runner config (AWS)
├── stack.toml                     # CloudFormation stack
├── sandbox.toml                   # EKS sandbox (default roles)
├── sandbox.tfvars                 # Cluster vars + custom role access entries
├── metadata.toml                  # App metadata
├── inputs.toml                    # User-facing inputs (domain)
│
├── components/
│   ├── whoami.toml                # Helm chart with deploy/teardown roles
│   ├── alb.toml                   # ALB ingress with deploy/teardown roles
│   ├── certificate.toml           # Terraform module with deploy/teardown roles
│   └── values/
│       └── whoami.yaml            # Helm values for whoami
│
├── actions/
│   ├── deployments_status.toml    # Read-only action (view role)
│   └── deployment_restart.toml    # Write action (edit role)
│
├── permissions/
│   ├── provision.toml             # Default provision role
│   ├── maintenance.toml           # Default maintenance role
│   ├── deprovision.toml           # Default deprovision role
│   ├── sandbox-provision.toml     # Custom: sandbox provision
│   ├── sandbox-maintenance.toml   # Custom: sandbox reprovision
│   ├── sandbox-deprovision.toml   # Custom: sandbox deprovision
│   ├── whoami-deploy.toml         # Custom: whoami deploy
│   ├── whoami-teardown.toml       # Custom: whoami teardown
│   ├── alb-deploy.toml            # Custom: alb deploy
│   ├── alb-teardown.toml          # Custom: alb teardown
│   ├── certificate-deploy.toml    # Custom: certificate deploy
│   ├── certificate-teardown.toml  # Custom: certificate teardown
│   ├── deployments-status-trigger.toml
│   ├── deployment-restart-trigger.toml
│   ├── provision_boundary.json    # Boundary for provision/deploy ops
│   ├── deprovision_boundary.json  # Boundary for teardown/deprovision ops
│   └── maintenance_boundary.json  # Boundary for action triggers
└
```

---

## App URL

[https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

```bash
curl https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
```

---

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

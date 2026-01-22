# Nuon App Configuration

This directory contains the Nuon configuration for the Uptime Monitor application. It defines how the app is packaged, deployed, and managed across customer installs.

## Documentation

- [Nuon Documentation](https://docs.nuon.co)
- [Configuration Files Reference](https://docs.nuon.co/configuration-files)
- [Example App Configs](https://github.com/nuonco/example-app-configs)

## Directory Structure

```
.
├── metadata.toml          # App metadata (name, description, readme)
├── sandbox.toml           # Base infrastructure (EKS cluster, VPC, DNS)
├── sandbox.tfvars         # Additional Terraform variables for sandbox
├── stack.toml             # CloudFormation stack for install bootstrapping
├── runner.toml            # Nuon runner configuration
├── inputs.toml            # User-configurable inputs
├── break_glass.toml       # Emergency access roles
│
├── components/            # Deployable units (images, Helm, K8s, Terraform)
│   ├── 0-api-image.toml   # Docker build: API image
│   ├── 0-ui-image.toml    # Docker build: UI image
│   ├── 1-s3.toml          # Terraform: S3 bucket
│   ├── 1-rds.toml         # Terraform: PostgreSQL RDS
│   ├── 1-irsa.toml        # Terraform: IAM role for service accounts
│   ├── 2-api.toml         # K8s manifest: API deployment
│   ├── 2-ui.toml          # K8s manifest: UI deployment
│   ├── 3-headlamp.toml    # Helm chart: Kubernetes dashboard
│   └── 4-alb.toml         # K8s manifest: Application Load Balancer
│
├── actions/               # Bash scripts for install operations
│   ├── rds_creds.toml     # Copy RDS credentials to K8s secret
│   ├── headlamp_token.toml # Generate Headlamp auth token
│   └── flush_healthchecks.toml # Cron job to clean old data
│
├── permissions/           # IAM roles for install lifecycle
│   ├── provision.toml     # Role for provisioning
│   ├── maintenance.toml   # Role for day-2 operations
│   ├── deprovision.toml   # Role for teardown
│   └── *_boundary.json    # Permission boundary policies
│
└── secrets/               # Secret definitions (if any)
```

## Configuration Overview

### Core Configuration Files

| File               | Purpose                                                     |
|--------------------|-------------------------------------------------------------|
| `metadata.toml`    | App display name, description, and README for the dashboard |
| `sandbox.toml`     | EKS cluster, VPC, DNS - the base infrastructure layer       |
| `stack.toml`       | CloudFormation template for bootstrapping installs          |
| `runner.toml`      | Nuon runner that executes deployments in customer accounts  |
| `inputs.toml`      | Customer-configurable values (e.g., healthcheck interval)   |
| `break_glass.toml` | Emergency access roles for incident response                |

### Components

Components are the deployable units of your app. See [components/README.md](components/README.md) for details.

**Supported types:**
- `docker_build` - Build images from Dockerfiles
- `container_image` - Reference pre-built images
- `helm_chart` - Deploy Helm charts
- `kubernetes_manifest` - Deploy raw K8s YAML
- `terraform_module` - Provision cloud infrastructure

### Actions

Actions are bash scripts triggered manually, on schedules, or by lifecycle events. See [actions/README.md](actions/README.md) for details.

### Permissions

IAM roles used during install lifecycle phases:
- **Provision**: Creates infrastructure during initial install
- **Maintenance**: Day-2 operations (deployments, updates)
- **Deprovision**: Tears down infrastructure on uninstall

## Template Variables

Nuon uses Go templating throughout configuration files. Common variables:

```
# Install information
{{.nuon.install.id}}                    # Unique install identifier
{{.nuon.install.name}}                  # Install name
{{.nuon.app.name}}                      # App name

# User inputs (from inputs.toml)
{{.nuon.install.inputs.INPUT_NAME}}

# CloudFormation stack outputs
{{.nuon.install_stack.outputs.region}}
{{.nuon.install_stack.outputs.vpc_id}}

# Sandbox outputs
{{.nuon.install.sandbox.outputs.vpc.id}}
{{.nuon.install.sandbox.outputs.cluster.oidc_provider}}
{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}

# Component outputs
{{.nuon.components.COMPONENT.outputs.OUTPUT_NAME}}

# Docker image outputs
{{.nuon.components.IMAGE.outputs.image.repository}}
{{.nuon.components.IMAGE.outputs.image.tag}}
```

## Syncing Configuration

After making changes, sync to Nuon:

```bash
cd uptime-monitor
nuon apps sync
```

This validates syntax, uploads configuration, and triggers builds for changed components.

## Schema Validation

Each config file supports JSON schema validation. Add this line at the top of your file for editor support:

```toml
#:schema https://api.nuon.co/v1/general/config-schema?type=TYPE
```

Valid types: `metadata`, `sandbox`, `stack`, `runner`, `input`, `input-group`, `action`, `helm`, `terraform`, `docker-build`, `kubernetes-manifest`, `container-image`, `break-glass`

---

# README Interpolation

This README file (referenced in `metadata.toml`) is rendered per-install in the Nuon dashboard. It supports Go templating with access to the full install state via the `.nuon` object.

## How It Works

When viewing an install in the dashboard, Nuon renders this README server-side, replacing template variables with actual values from that specific install. This allows you to show install-specific information like URLs, tokens, and status.

## The `.nuon` Object

The `.nuon` object contains the complete install state. Key attributes:

### App Information
```
{{.nuon.app.name}}                      # App name from metadata.toml
{{.nuon.app.id}}                        # App ID
```

### Install Information
```
{{.nuon.install.id}}                    # Unique install identifier
{{.nuon.install.name}}                  # Install name
{{.nuon.install.inputs.INPUT_NAME}}     # User-provided input values
```

### Sandbox Information
```
{{.nuon.sandbox.type}}                  # Sandbox type (e.g., "aws-eks")
{{.nuon.install.sandbox.outputs.X}}     # Any Terraform output from sandbox
```

Common sandbox outputs (aws-eks-sandbox):
```
{{.nuon.install.sandbox.outputs.vpc.id}}
{{.nuon.install.sandbox.outputs.vpc.private_subnet_ids}}
{{.nuon.install.sandbox.outputs.cluster.cluster_name}}
{{.nuon.install.sandbox.outputs.cluster.oidc_provider}}
{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
{{.nuon.install.sandbox.outputs.nuon_dns.internal_domain.name}}
{{.nuon.install.sandbox.outputs.account.aws_region}}
```

### Install Stack (CloudFormation) Outputs
```
{{.nuon.install_stack.outputs.region}}
{{.nuon.install_stack.outputs.vpc_id}}
```

### Component Information
```
{{.nuon.components.populated}}          # Boolean: are components deployed?
{{.nuon.components.components}}         # Map of all components

# Iterate over components:
{{range $name, $component := .nuon.components.components}}
  {{$name}}: {{$component.status}}
{{end}}

# Access specific component outputs:
{{.nuon.components.COMPONENT_NAME.outputs.OUTPUT_NAME}}
{{.nuon.components.s3.outputs.bucket_name}}
{{.nuon.components.rds.outputs.db_host}}
```

### Action Workflow Outputs
```
# Access output from a completed action step:
{{.nuon.actions.workflows.ACTION_NAME.outputs.steps.STEP_NAME.OUTPUT_KEY}}

# Example: Get token from headlamp_token action's "create" step:
{{.nuon.actions.workflows.headlamp_token.outputs.steps.create.token}}
```

### Secrets
```
{{.nuon.secrets.SECRET_NAME}}           # Synced secret values
```

## Go Template Functions

READMEs support full Go templating syntax:

### Conditionals
```
{{ if .nuon.components.populated }}
  Components are deployed!
{{ else }}
  No components yet.
{{ end }}
```

### Loops
```
| Component | Status |
|-----------|--------|
{{- range $name, $component := .nuon.components.components }}
| {{ $name }} | {{ $component.status }} |
{{- end }}
```

### JSON Output
```
{{ toPrettyJson .nuon }}                # Pretty-print entire state as JSON
```

## Debugging

To inspect the full `.nuon` object structure, add this to your README:

```markdown
<details>
  <summary>Full Install State</summary>
  <pre>{{ toPrettyJson .nuon }}</pre>
</details>
```

This renders a collapsible section showing all available data for the install.

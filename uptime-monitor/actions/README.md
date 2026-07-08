# Actions

Actions are bash scripts that run in the context of an install. They can be triggered manually, on a schedule, or by lifecycle events (e.g., after a component deploys).

## Trigger Types

| Trigger                 | Description                    | Example Use Case                     |
|-------------------------|--------------------------------|--------------------------------------|
| `manual`                | Run from dashboard or CLI      | Debugging, one-off tasks             |
| `cron`                  | Run on a schedule              | Cleanup jobs, health checks          |
| `post-deploy-component` | Run after a component deploys  | Initialize databases, create secrets |
| `pre-deploy-component`  | Run before a component deploys | Validate prerequisites               |
| `post-provision`        | Run after install provisioning | Initial setup tasks                  |
| `post-update-inputs`    | Run after inputs are updated   | Apply configuration changes          |

## Actions in This App

| Action                    | Triggers                                 | Description                                                            |
|---------------------------|------------------------------------------|------------------------------------------------------------------------|
| `rds_creds.toml`          | post-deploy-component (rds), manual      | Copies RDS credentials from AWS Secrets Manager to a Kubernetes secret |
| `headlamp_token.toml`     | post-deploy-component (headlamp), manual | Generates a Kubernetes token for Headlamp dashboard access             |
| `flush_healthchecks.toml` | cron (hourly), manual                    | Deletes healthcheck records older than 24 hours                        |

## Writing Action Scripts

### Inline Scripts

```toml
[[steps]]
name = "my-step"
inline_contents = """
#!/usr/bin/env bash
set -euo pipefail
echo "Hello from $INSTALL_ID"
"""

[steps.env_vars]
INSTALL_ID = "{{ .nuon.install.id }}"
```

### Scripts from Repository

```toml
[[steps]]
name = "my-step"
command = "./scripts/my-script.sh"

[steps.public_repo]
repo      = "nuonco/uptime-monitor"
directory = "scripts"
branch    = "main"
```

## Environment Variables

Actions have access to:

- **Custom env_vars**: Defined in the action config with Nuon template variables
- **`$NUON_ACTIONS_OUTPUT_FILEPATH`**: Write JSON here to return structured output to the dashboard

### Template Variables in env_vars

```toml
[steps.env_vars]
# Component outputs
BUCKET_NAME = "{{ .nuon.components.s3.outputs.bucket_name }}"
DB_HOST     = "{{ .nuon.components.rds.outputs.db_host }}"

# Install info
INSTALL_ID = "{{ .nuon.install.id }}"
REGION     = "{{ .nuon.install_stack.outputs.region }}"

# User inputs
INTERVAL = "{{ .nuon.install.inputs.healthcheck_interval_seconds }}"
```

## Returning Output

Actions can return structured data to the Nuon dashboard:

```bash
#!/usr/bin/env bash
TOKEN=$(kubectl create token my-service-account)
printf '{"token": "%s"}' "$TOKEN" >> $NUON_ACTIONS_OUTPUT_FILEPATH
```

The output appears in the dashboard after the action completes.

## Break Glass Roles

For actions requiring elevated permissions, specify a break glass role:

```toml
name = "emergency-repair"
break_glass_role = "sandbox-break-glass"
```

## Documentation

- [Actions Overview](https://docs.nuon.co/concepts/actions)
- [Configuring Actions](https://docs.nuon.co/guides/actions)
- [Break Glass](https://docs.nuon.co/production-readiness/break-glass)

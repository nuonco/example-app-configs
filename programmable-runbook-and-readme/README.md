# programmable-runbook-and-readme

A [Nuon](https://nuon.co) app config that deploys
[`traefik/whoami`](https://hub.docker.com/r/traefik/whoami) onto **AWS EKS (Auto
Mode)** and demonstrates two Nuon features:

- **Runbooks** — named, ordered procedures you run against an install on demand
  (think: a notebook of operational steps), defined as TOML in [`runbooks/`](./runbooks).
- **Rendered READMEs** — Markdown with Go templating and `<nuon-*>` components,
  resolved per-install against live values.

It is built on the [`eks-simple-auto`](../eks-simple-auto) example, extended with
a `runbooks/` directory and README content. The component, sandbox, and action
sources point at their original public repos (`nuonco/aws-eks-auto-sandbox`,
`nuonco/components`, `nuonco/actions`), so nothing is self-hosted.

> [!NOTE]
> The Nuon **app name must equal this directory name** (`nuon sync` uses the
> directory name to find the app). Keep the directory named
> `programmable-runbook-and-readme`.

## What's in here

```
programmable-runbook-and-readme/
├── metadata.toml          # app metadata; readme = ./app-readme.md
├── app-readme.md          # per-install rendered README (templated, embeds runbooks)
├── inputs.toml            # whoami name + subdomain inputs
├── sandbox.toml           # aws-eks-auto-sandbox (Terraform)
├── sandbox.tfvars         # EKS Auto Mode sandbox vars
├── stack.toml             # CloudFormation install stack (VPC + runner)
├── runner.toml            # AWS runner config
├── components/            # whoami (manifest), application_load_balancer (helm), certificate (tf)
├── actions/               # deployments_restart, simple_demonstration
├── runbooks/              # ← the runbooks demo
│   ├── restart-and-verify.toml + restart-and-verify.md
│   └── whoami-smoke-test.toml   + whoami-smoke-test.md
├── permissions.toml + permissions/   # provision / maintenance / deprovision roles
├── policies.toml + policies/         # OPA-style cluster guardrails
├── break_glass.toml                  # break-glass role
└── secrets.toml
```

## The runbooks

Both runbooks reference only components/actions that exist in this config.

### `restart-and-verify` — the on-call restart, encoded (premier example)

| Step | Type | What it does |
|------|------|--------------|
| `restart` | `action` | Runs the existing **`deployments_restart`** action (`kubectl rollout restart`) to roll the `whoami` Deployment. |
| `verify` | `action` | An **inline** `command` that `curl`s the live whoami URL (templated from the `subdomain` input + sandbox DNS), retrying until it returns a healthy status. |

The everyday on-call procedure — _restart the wedged service, confirm it's
serving again_ — as one named, recorded, re-runnable artifact. Both steps run
every time (no no-op skips), composing an **existing** action with an **inline**
check. Has its own templated README
([`runbooks/restart-and-verify.md`](./runbooks/restart-and-verify.md)).

### `whoami-smoke-test` — inline ad-hoc action

| Step | Type | What it does |
|------|------|--------------|
| `curl-whoami` | `action` | An **inline** `command` that `curl`s the live whoami URL (built with Go templating from the `subdomain` input and the sandbox DNS output), with a static `MAX_RETRIES` env var and a `5m` timeout. |

Demonstrates an **inline** action step (no separate action definition). Has its
own templated README ([`runbooks/whoami-smoke-test.md`](./runbooks/whoami-smoke-test.md)).

Runbook schema reference: `pkg/config/runbook_config.go` in
[`nuonco/nuon`](https://github.com/nuonco/nuon). Guide: `docs/guides/runbooks.mdx`.

## The READMEs

- **App README** ([`app-readme.md`](./app-readme.md), wired via `readme` in
  `metadata.toml`) renders per-install. It surfaces live values
  (`{{ .nuon.install.id }}`, account/region/VPC, install-stack quicklink, sandbox
  state, component statuses) and embeds both runbooks as runnable cards via
  `<nuon-run-runbook name="...">`, alongside `<nuon-component-card>` and
  `<nuon-banner>` components.
- **Runbook READMEs** (`runbooks/*.md`, wired via each runbook's `readme` field)
  document each procedure with templated values and display components.

READMEs guide: `docs/guides/using-readmes.mdx` in `nuonco/nuon`.

## Sync it and try it

```bash
# From a clone of this repo:
cd example-app-configs/programmable-runbook-and-readme

# Authenticate the CLI (browser SSO)
nuon auth login

# Create the app in the control plane, then sync this config.
# The app name is taken from the directory name (programmable-runbook-and-readme).
nuon apps create --name programmable-runbook-and-readme   # first time only
nuon sync                                            # run from inside this directory
```

Then, in the [dashboard](https://app.nuon.co/):

1. Create an install of the app and let the sandbox/runner provision.
2. Open the install's **Overview** — the rendered app README appears, with the
   two runbooks embedded as runnable cards.
3. Open the **Runbooks** tab and run `restart-and-verify`, then `whoami-smoke-test`.

Or run a runbook from the CLI:

```bash
nuon runbooks --install-id <install-id>
```

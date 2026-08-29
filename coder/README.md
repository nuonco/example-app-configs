{{ $nuonRoot := default dict .nuon }}
{{ $install     := default dict (dig "install" dict $nuonRoot) }}
{{ $installStack := default dict (dig "install_stack" dict $nuonRoot) }}
{{ $actionsMap  := default dict (dig "actions" dict $nuonRoot) }}
{{ $workflows   := default dict (dig "workflows" dict $actionsMap) }}
{{ $installID   := dig "id" "" $install }}

{{ $k8s     := default dict (dig "k8s_status" dict $workflows) }}
{{ $coder   := default dict (dig "coder_health" dict $workflows) }}
{{ $alb     := default dict (dig "alb_healthcheck" dict $workflows) }}
{{ $grafana := default dict (dig "grafana_health" dict $workflows) }}
{{ $prom    := default dict (dig "prom_targets" dict $workflows) }}

{{ $k8sOut     := default dict (dig "outputs" dict $k8s) }}
{{ $coderOut   := default dict (dig "outputs" dict $coder) }}
{{ $albOut     := default dict (dig "outputs" dict $alb) }}
{{ $grafanaOut := default dict (dig "outputs" dict $grafana) }}
{{ $promOut    := default dict (dig "outputs" dict $prom) }}

{{ $k8sID    := dig "id" "" $k8s }}
{{ $coderID  := dig "id" "" $coder }}
{{ $albID    := dig "id" "" $alb }}
{{ $grafanaID := dig "id" "" $grafana }}
{{ $promID   := dig "id" "" $prom }}

{{ $k8sInd   := dig "indicator" "" $k8sOut }}
{{ $coderInd := dig "indicator" "" $coderOut }}
{{ $grafInd  := dig "indicator" "" $grafanaOut }}
{{ $promInd  := dig "indicator" "" $promOut }}

{{ $albCoderMap := default dict (dig "coder" dict $albOut) }}
{{ $albGrafMap  := default dict (dig "grafana" dict $albOut) }}
{{ $albCoder    := dig "indicator" "" $albCoderMap }}
{{ $albGraf     := dig "indicator" "" $albGrafMap }}

{{ $hcAllGreen := and (eq $k8sInd "🟢") (eq $coderInd "🟢") (eq $albCoder "🟢") (eq $albGraf "🟢") (eq $grafInd "🟢") (eq $promInd "🟢") }}
{{ $hcAnyRed   := or  (eq $k8sInd "🔴") (eq $coderInd "🔴") (eq $albCoder "🔴") (eq $albGraf "🔴") (eq $grafInd "🔴") (eq $promInd "🔴") }}

{{ $dh    := default dict (dig "coder_deployment_health" dict $workflows) }}
{{ $dhOut    := default dict (dig "outputs" dict $dh) }}
{{ $dhSub    := default dict (dig "subsystems" dict $dhOut) }}
{{ $dhReady  := and (dig "populated" false $dh) (eq (dig "status" "" $dh) "finished") }}
{{ $dhID     := dig "id" "" $dh }}

{{ $promUpdated := dig "updated_at" "" $promOut }}
{{ $dhUpdated   := dig "updated_at" "" $dhOut }}

{{ $bgClean  := default dict (dig "k8s_clean_failed_pods" dict $workflows) }}
{{ $bgCleanUpdated  := dig "updated_at" "" (default dict (dig "outputs" dict $bgClean)) }}

{{ $sandbox  := default dict (dig "sandbox" dict $install) }}
{{ $sbOut    := default dict (dig "outputs" dict $sandbox) }}
{{ $nuonDNS  := default dict (dig "nuon_dns" dict $sbOut) }}
{{ $pubDomainMap := default dict (dig "public_domain" dict $nuonDNS) }}
{{ $domain   := dig "name" "" $pubDomainMap }}

{{ $stackOut := default dict (dig "outputs" dict $installStack) }}
{{ $region   := dig "region" "" $stackOut }}

<div style="display:flex; width:100%; align-items:center; justify-content:space-between; padding-bottom:1rem;">
  <video autoplay loop muted playsinline width="480" height="270">
    <source src="https://coder.together.agency/videos/logo/sections/0/content/9/value/video.mp4" type="video/mp4">
    Your browser does not support the video tag.
  </video>
  <div style="display:flex; flex-direction:column; gap:10px; align-items:flex-end;">
    <div style="display:flex; gap:10px; align-items:center;">
      <a href="https://{{ $domain }}" style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:#8b5cf6; color:white; border-radius:8px; text-decoration:none; font-weight:600; font-size:15px;">Open Coder →</a>
      <a href="https://{{ $domain }}/grafana" style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:transparent; color:#c4b5fd; border:1px solid rgba(139,92,246,0.6); border-radius:8px; text-decoration:none; font-weight:600; font-size:15px;">Open Grafana →</a>
    </div>
    <div style="display:flex; flex-direction:column; align-items:flex-end; gap:2px;">
      <nuon-run-runbook name="healthcheck_infra"></nuon-run-runbook>
      {{ with $promUpdated }}<span style="font-size:0.75em; color:#6b7280;">Last run <nuon-time time="{{ . }}" format="relative"></nuon-time></span>{{ end }}
    </div>
    <div style="display:flex; flex-direction:column; align-items:flex-end; gap:2px;">
      <nuon-run-runbook name="breakglass_k8s_remediate"></nuon-run-runbook>
      {{ with $bgCleanUpdated }}<span style="font-size:0.75em; color:#6b7280;">Last run <nuon-time time="{{ . }}" format="relative"></nuon-time></span>{{ end }}
    </div>
  </div>
</div>

<nuon-banner theme="success">
Coder's cloud development environment platform — for developers and agents. The links and status below are live for this install.
</nuon-banner>

<br/>

<nuon-group gap="8" align="center">
  <nuon-label-badge label="install:{{ $installID }}"></nuon-label-badge>
  <nuon-label-badge label="region:{{ $region }}"></nuon-label-badge>
  <nuon-label-badge label="sandbox:eks-auto"></nuon-label-badge>
</nuon-group>

<nuon-tabs>

<nuon-tab name="overview">

<br/>

<div style="display:flex; flex-direction:column;">

<div style="display:flex; align-items:baseline; gap:0.75rem; margin-top:1.25rem; margin-bottom:0.5rem;">
  <p style="font-size:1.05rem; font-weight:700; margin:0;">Infra health</p>
  {{ with $promUpdated }}<span style="margin-left:auto; font-size:0.85em; color:#6b7280;">Last updated <nuon-time time="{{ . }}" format="relative"></nuon-time></span>{{ end }}
</div>

<nuon-group gap="8" align="center">
  {{ if $hcAllGreen }}<nuon-status status="active" variant="badge"></nuon-status>
  {{ else if $hcAnyRed }}<nuon-status status="error" variant="badge"></nuon-status>
  {{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}
  <span>Rolled-up status across cluster, Coder, ALB, Grafana, and Prometheus.</span>
</nuon-group>

<table>
  <thead><tr><th>Subsystem</th><th>Status</th><th>Action</th></tr></thead>
  <tbody>
    <tr><td>Kubernetes</td><td>{{ if eq $k8sInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $k8sInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td><a href="./{{ $installID }}/actions/{{ $k8sID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">k8s_status</code></a></td></tr>
    <tr><td>Coder API</td><td>{{ if eq $coderInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $coderInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td><a href="./{{ $installID }}/actions/{{ $coderID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">coder_health</code></a></td></tr>
    <tr><td>ALB · Coder ingress</td><td>{{ if eq $albCoder "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $albCoder "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td><a href="./{{ $installID }}/actions/{{ $albID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code></a></td></tr>
    <tr><td>ALB · Grafana ingress</td><td>{{ if eq $albGraf "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $albGraf "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td><a href="./{{ $installID }}/actions/{{ $albID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code></a></td></tr>
    <tr><td>Grafana</td><td>{{ if eq $grafInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $grafInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td><a href="./{{ $installID }}/actions/{{ $grafanaID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">grafana_health</code></a></td></tr>
    <tr><td>Prometheus</td><td>{{ if eq $promInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $promInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td><a href="./{{ $installID }}/actions/{{ $promID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">prom_targets</code></a></td></tr>
  </tbody>
</table>

<div style="display:flex; align-items:baseline; gap:0.75rem; margin-top:1.25rem; margin-bottom:0.5rem;">
  <p style="font-size:1.05rem; font-weight:700; margin:0;">Coder health</p>
  <span style="font-size:0.85em; color:#6b7280;">action:</span> <a href="./{{ $installID }}/actions/{{ $dhID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">coder_deployment_health</code></a>
  {{ with $dhUpdated }}<span style="margin-left:auto; font-size:0.85em; color:#6b7280;">Last updated <nuon-time time="{{ . }}" format="relative"></nuon-time></span>{{ end }}
</div>

{{ if $dhReady }}
<table>
  <thead><tr><th>Subsystem</th><th>Status</th></tr></thead>
  <tbody>
    <tr><td>Access URL</td><td>{{ $s := dig "access_url" "" $dhSub }}{{ if eq $s "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $s "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td></tr>
    <tr><td>DERP</td><td>{{ $s := dig "derp" "" $dhSub }}{{ if eq $s "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $s "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td></tr>
    <tr><td>Websocket</td><td>{{ $s := dig "websocket" "" $dhSub }}{{ if eq $s "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $s "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td></tr>
    <tr><td>Workspace proxy</td><td>{{ $s := dig "workspace_proxy" "" $dhSub }}{{ if eq $s "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $s "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td></tr>
  </tbody>
</table>
{{ else }}
<nuon-banner theme="warn">Waiting on <code>coder_deployment_health</code>.</nuon-banner>
{{ end }}

</div>

### What's deployed

<nuon-group gap="8">
  <nuon-component-card name="rds_subnet"></nuon-component-card>
  <nuon-component-card name="rds_cluster_coder"></nuon-component-card>
  <nuon-component-card name="coder_pod_identity"></nuon-component-card>
  <nuon-component-card name="coder"></nuon-component-card>
  <nuon-component-card name="certificate"></nuon-component-card>
  <nuon-component-card name="application_load_balancer"></nuon-component-card>
  <nuon-component-card name="kubelogstream"></nuon-component-card>
  <nuon-component-card name="observability"></nuon-component-card>
</nuon-group>

- [Coder documentation](https://coder.com/docs)
- [Workspace templates](https://coder.com/docs/templates)
- [User management](https://coder.com/docs/admin/users)

</nuon-tab>

<nuon-tab name="architecture">

<br/>

<nuon-panel heading="System diagram" trigger="View" size="3/4">

```mermaid

  graph TD

      subgraph Nuon["Nuon Control Plane"]
          NuonAPI["Nuon API"]
      end

      subgraph Clients["Clients"]
          Customer["Customer / Admin"]
          IDE["IDE with SSH"]
          Dashboard["Coder & Grafana Dashboards & Web IDE"]
          Customer ~~~ IDE ~~~ Dashboard
      end

      subgraph VPC["Customer Cloud VPC (AWS)"]
          Runner["Nuon Runner"]
          RDS[("PostgreSQL RDS<br/>(IAM auth required)")]
          PodIdentity["EKS Pod Identity<br/>(coder IAM role: rds-db:connect)"]
          ACM["ACM Certificate"]
          ALB["Application Load Balancer"]
          Stack["CloudFormation Stack<br/>(anthropic_api_key parameter)"]
          SM[("AWS Secrets Manager<br/>anthropic_api_key")]

          subgraph EKS["EKS Cluster"]
              K8sSecret[("Kubernetes Secret<br/>coder-anthropic-key")]
              ExporterSecret[("Kubernetes Secret<br/>coder-db-password")]
              Coder["Coder<br/>(AI Gateway)"]
              Logstream["Kubelogstream"]
              Observability["Grafana & Prometheus Observability<br/>(coder_exporter user)"]
              DevEnv["Development Environment"]
          end
      end

      NuonAPI -->|generates template| Stack
      Customer -->|applies CloudFormation Stack<br/>with anthropic_api_key| Stack
      Stack -->|CloudFormation provisions| Runner
      Stack -->|CloudFormation writes key to| SM
      Runner -->|provisions| EKS
      Runner -->|provisions| RDS
      Runner -->|provisions| PodIdentity
      Runner -->|provisions| ACM
      Runner -->|provisions| ALB
      Runner -->|provisions| Coder
      Runner -->|provisions| Logstream
      Runner -->|provisions| Observability
      Runner -->|reads anthropic_api_key| SM
      Runner -->|syncs to| K8sSecret
      Runner -->|coder_db_init: creates coder_exporter,<br/>grants rds_iam, syncs password to| ExporterSecret
      K8sSecret -->|CODER_AI_GATEWAY_ANTHROPIC_KEY| Coder
      ExporterSecret -->|PGPASSWORD| Observability

      ACM -->|TLS| ALB
      ALB --> Coder
      Coder -->|assumes| PodIdentity
      PodIdentity -.->|rds-db:connect<br/>short-lived token| RDS
      RDS -->|DB via IAM token| Coder
      RDS -->|DB via password| Observability
      Coder --> Observability
      ALB --> Observability
      Dashboard -->|HTTPS| ALB
      Coder --> DevEnv
      IDE -->|HTTPS| DevEnv
      IDE -->|HTTPS| ALB
      Logstream --> DevEnv

```

</nuon-panel>

### Components

<nuon-group gap="8">
  <nuon-component-card name="rds_subnet"></nuon-component-card>
  <nuon-component-card name="rds_cluster_coder"></nuon-component-card>
  <nuon-component-card name="coder_pod_identity"></nuon-component-card>
  <nuon-component-card name="coder"></nuon-component-card>
  <nuon-component-card name="certificate"></nuon-component-card>
  <nuon-component-card name="application_load_balancer"></nuon-component-card>
  <nuon-component-card name="kubelogstream"></nuon-component-card>
  <nuon-component-card name="observability"></nuon-component-card>
</nuon-group>

### Where it runs

Coder runs entirely inside your AWS VPC — both its control plane (the Coder server, web UI, and AI gateway) and its data plane (the RDS database cluster and the developer workspaces themselves). Grafana is also deployed in the VPC. 

</nuon-tab>

<nuon-tab name="configuration">

<br/>

{{ $in := default dict (dig "inputs" dict $install) }}

Inputs split into two groups by who owns the change. Customer-controlled inputs are exposed in **Current Inputs** and safe to tune any time. Vendor-controlled inputs are managed by the vendor through app config updates and not visible to the install operator.

### Customer-controlled

Tune these from **Current Inputs → Edit Inputs**. Changes trigger a redeploy of affected components — the workflow shows a diff and pauses for approval before applying.

| Input | Current value | Description |
|---|---|---|
| `telemetry` | `{{ dig "telemetry" "—" $in }}` | Send usage telemetry to Coder |
| `max_token_lifetime` | `{{ dig "max_token_lifetime" "—" $in }}` | Maximum lifetime for CLI and API tokens |
| `session_duration` | `{{ dig "session_duration" "—" $in }}` | Session duration before re-authentication is required |
| `block_direct` | `{{ dig "block_direct" "—" $in }}` | Force all workspace connections through the Coder relay (disables peer-to-peer) |

### Vendor-controlled

The vendor pins these in the app config and updates them via release. The big one is `release` — the Coder version itself, which the vendor schedules into your install on their cadence.

| Input | Current value | Description |
|---|---|---|
| `release` | `{{ dig "release" "—" $in }}` | Coder release version — vendor schedules upgrades |
| `replicas` | `{{ dig "replicas" "—" $in }}` | Coder control plane replica count |
| `provisioners` | `{{ dig "provisioners" "—" $in }}` | Terraform provisioners for workspace lifecycle |
| `cluster_version` | `{{ dig "cluster_version" "—" $in }}` | EKS Kubernetes version |
| `coder_db_instance_type` | `{{ dig "coder_db_instance_type" "—" $in }}` | RDS instance type |

> [!IMPORTANT]
> Vendor-side changes to `cluster_version` or `coder_db_instance_type` trigger infrastructure changes that can take 15+ minutes to apply. The vendor stages these during an agreed maintenance window.

</nuon-tab>

<nuon-tab name="agents">

<br/>

Coder ships a built-in AI gateway that turns this install into a hosted home for [Coder Agents](https://coder.com/docs/ai-coder/agents) — Anthropic-powered coding agents that run in the control plane (not inside the workspace) so prompts, diffs, and tool calls are auditable and isolated from your code.

### What your developers get

- A chat UI in the Coder web app (or via the REST API) for running an agent — the agent loop runs in the Coder control plane, not inside the workspace, so prompts stay isolated from the code being edited
- Centralized auth — developers use their Coder login, not a personal Anthropic key
- An audit trail of every prompt and tool invocation, attributed back to the user

[Coder AI Gateway docs](https://coder.com/docs/ai-coder/ai-gateway)

### How to enable

> [!NOTE]
> Your Anthropic API key never touches Nuon or the vendor. It is written directly to your AWS Secrets Manager by the CloudFormation stack you applied at install time, then synced into the EKS cluster.

1. Grab a key from [console.anthropic.com](https://console.anthropic.com)
2. Re-apply the install stack CloudFormation template with the `anthropic_api_key` parameter populated (or set it the first time around)
3. Nuon stores the value in AWS Secrets Manager and syncs it to a Kubernetes Secret named `coder-anthropic-key` in the `coder` namespace
4. The Coder server picks it up via the `CODER_AI_GATEWAY_ANTHROPIC_KEY` environment variable

If you leave the CloudFormation parameter blank, Coder still boots normally — a Coder admin can add the Anthropic key directly through the Coder dashboard instead.

### Rotating the key

Update the parameter in the install stack and re-run the secret sync from the **Operations** tab.

</nuon-tab>

<nuon-tab name="grafana">

<br/>

Grafana is served from the same load balancer as Coder, at <nuon-badge theme="default" variant="code">https://{{ $domain }}/grafana</nuon-badge>.

### Get the admin password

<nuon-action-card name="grafana_password"></nuon-action-card>

The output shows the URL, username (`admin`), and the generated password.

### Dashboards

- **Coder Status** — overall health overview
- **Coder Coderd** — control plane metrics
- **Workspaces** — utilization and performance
- **Workspace Detail** — per-workspace deep-dive
- **Provisioner** — Terraform provisioner metrics
- **Postgres Database** — RDS performance
- **Infrastructure** — node-level metrics

[Coder monitoring guide](https://coder.com/docs/admin/monitoring)

</nuon-tab>

<nuon-tab name="upgrade">

<br/>

The Coder version is pinned by the `release` input on this install. Bumping it triggers a helm upgrade — you review the diff, then approve.

### Steps

1. Click **Current Inputs → Edit Inputs**
2. Set the new version. e.g., v2.34.2 Valid tags: [github.com/coder/coder/releases](https://github.com/coder/coder/releases).
3. Save. A workflow appears in **Workflows** with a helm diff. Review and approve to apply.

> [!WARNING]
> Major Coder upgrades may include database migrations. Migrations run as part of the helm upgrade and are **not separately reversible**. Read the [release notes](https://github.com/coder/coder/releases) before approving.

</nuon-tab>

<nuon-tab name="operations">

<br/>

This app's installs are managed as code: each has a corresponding TOML file under [`installs/`](./installs) holding its labels, approval behavior, and any per-install overrides. Docs: [Install Configs guide](https://docs.nuon.co/guides/install-configs), [Install config reference](https://docs.nuon.co/config-ref/install).

### Bootstrap an install from a config file

1. Generate a config from an existing install (or copy an example from [`installs/`](./installs)):
   ```sh
   nuon installs generate-config -i <install-name> > installs/<install-name>.toml
   ```
2. Edit `[labels]`, `approval_option`, `[aws_account]`, or `[[inputs]]` as needed.
3. Apply it. `-d` accepts either a single file or a directory:

   Sync just one install (e.g. while testing a change against `canary` only, without touching the three customer installs):
   ```sh
   nuon installs sync -a coder -d installs/canary.toml
   ```

   Sync every install config in the directory at once:
   ```sh
   nuon installs sync -a coder -d installs/
   ```

### Release channels

Installs are labeled into a single lane: a canary gating its promotion to prod. A connected app branch (`branches/main.toml`) rolls changes through the lane in order:

| Channel | Label | Installs | Approval | Gets changes |
|---|---|---|---|---|
| Canary | `canary=true` | `canary` | auto | first |
| Prod | `prod=true` | `customer-1`, `customer-2`, `customer-3` | auto | second |

A push to `main` builds the change and deploys to `canary` immediately, then to `prod` once canary succeeds — all installs use `approval_option = "approve-all"`, so no manual approval gates the rollout. Opening a PR against `main` instead produces a plan-only diff scoped to the canary group, so reviewers see the smallest-blast-radius preview before anything merges. See the [app branches guide](https://docs.nuon.co/guides/app-branches).

### Opting an install out

`nuon installs toggle-sync --disable -i <install-name>` removes an install from config-file management entirely (dashboard-only from then on); `--enable` reverses it.

</nuon-tab>

<nuon-tab name="resources">

<br/>

- [Coder Documentation](https://coder.com/docs)
- [Coder Releases](https://github.com/coder/coder/releases/)
- [Coder Monitoring](https://coder.com/docs/admin/monitoring)
- [Coder CLI Reference](https://coder.com/docs/reference/cli/server)
- [Coder OSS Repository](https://github.com/coder/coder)
- [Coder Agents (AI)](https://coder.com/docs/ai-coder/agents)
- [Coder AI Gateway](https://coder.com/docs/ai-coder/ai-gateway)
- [AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

<nuon-panel heading="Cost estimate" trigger="View">

Running this app in your environment will cost around **$8/day** at the default sizing. The bulk is EKS Auto Mode nodes + RDS Postgres + ALB hours. Scaling Coder replicas, raising the RDS instance class, or driving high workspace counts will push this higher — check the [AWS Instance Types](https://aws.amazon.com/ec2/instance-types/) reference for marginal cost.

</nuon-panel>

</nuon-tab>

</nuon-tabs>

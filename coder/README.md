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

{{ $labels      := default dict (dig "labels" dict $install) }}
{{ if eq (len $labels) 0 }}{{ $labels = default dict (dig "labels" dict $nuonRoot) }}{{ end }}
{{ $fleet       := dig "fleet" "" $labels }}
{{ $wave        := dig "wave" "" $labels }}
{{ $channel     := dig "channel" "" $labels }}
{{ $installName := dig "name" "" $install }}
{{ $inEarly     := default dict (dig "inputs" dict $install) }}
{{ $coderTag    := dig "coder_image_tag" "v2.33.10" $inEarly }}
{{ $releaseLbl  := dig "release" "" $labels }}
{{ if eq $releaseLbl "" }}{{ $releaseLbl = $coderTag }}{{ end }}

<div style="display:flex; width:100%; align-items:center; justify-content:space-between; padding-bottom:1rem;">
  <video autoplay loop muted playsinline width="480" height="270">
    <source src="https://coder.together.agency/videos/logo/sections/0/content/9/value/video.mp4" type="video/mp4">
    Your browser does not support the video tag.
  </video>
  <div style="display:flex; flex-direction:column; gap:10px; align-items:flex-end;">
    <div style="display:flex; gap:10px; align-items:center;">
      {{ if $domain -}}
      <a href="https://{{ $domain }}" style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:#8b5cf6; color:white; border-radius:8px; text-decoration:none; font-weight:600; font-size:15px;">Open Coder →</a>
      <a href="https://{{ $domain }}/grafana" style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:transparent; color:#c4b5fd; border:1px solid rgba(139,92,246,0.6); border-radius:8px; text-decoration:none; font-weight:600; font-size:15px;">Open Grafana →</a>
      {{ else -}}
      <span style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:#8b5cf6; color:white; border-radius:8px; font-weight:600; font-size:15px; opacity:0.55;">Open Coder →</span>
      <span style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:transparent; color:#c4b5fd; border:1px solid rgba(139,92,246,0.6); border-radius:8px; font-weight:600; font-size:15px; opacity:0.55;">Open Grafana →</span>
      {{ end -}}
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

{{ if not $domain -}}
<nuon-banner theme="warn">
Provisioning in progress — Coder and Grafana URLs appear here when the sandbox DNS record is ready.
</nuon-banner>
{{ else -}}
<nuon-banner theme="success">
Coder's cloud development environment platform — for developers and agents. The links and status below are live for this install.
</nuon-banner>
{{ end -}}

<br/>

<nuon-group gap="8" align="center">
  {{ if $channel }}<nuon-label-badge label="channel:{{ $channel }}"></nuon-label-badge>{{ end }}
  {{ if $releaseLbl }}<nuon-label-badge label="release:{{ $releaseLbl }}"></nuon-label-badge>{{ end }}
  {{ if eq $fleet "true" }}<nuon-label-badge label="fleet:true"></nuon-label-badge>{{ end }}
  {{ if $wave }}<nuon-label-badge label="wave:{{ $wave }}"></nuon-label-badge>{{ end }}
  {{ if $installName }}<nuon-label-badge label="install:{{ $installName }}"></nuon-label-badge>{{ end }}
  {{ if $region }}<nuon-label-badge label="region:{{ $region }}"></nuon-label-badge>{{ end }}
  <nuon-label-badge label="sandbox:eks-auto"></nuon-label-badge>
</nuon-group>
<p style="margin:0.5rem 0 0; font-size:0.9em; color:#6b7280;">Coder <code>{{ $coderTag }}</code> via install input <code>coder_image_tag</code> (drives the <code>release</code> label)</p>

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
    <tr><td>Kubernetes</td><td>{{ if eq $k8sInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $k8sInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $k8sID }}<a href="./{{ $installID }}/actions/{{ $k8sID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">k8s_status</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">k8s_status</code>{{ end }}</td></tr>
    <tr><td>Coder API</td><td>{{ if eq $coderInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $coderInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $coderID }}<a href="./{{ $installID }}/actions/{{ $coderID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">coder_health</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">coder_health</code>{{ end }}</td></tr>
    <tr><td>ALB · Coder ingress</td><td>{{ if eq $albCoder "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $albCoder "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $albID }}<a href="./{{ $installID }}/actions/{{ $albID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code>{{ end }}</td></tr>
    <tr><td>ALB · Grafana ingress</td><td>{{ if eq $albGraf "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $albGraf "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $albID }}<a href="./{{ $installID }}/actions/{{ $albID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code>{{ end }}</td></tr>
    <tr><td>Grafana</td><td>{{ if eq $grafInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $grafInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $grafanaID }}<a href="./{{ $installID }}/actions/{{ $grafanaID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">grafana_health</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">grafana_health</code>{{ end }}</td></tr>
    <tr><td>Prometheus</td><td>{{ if eq $promInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $promInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $promID }}<a href="./{{ $installID }}/actions/{{ $promID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">prom_targets</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">prom_targets</code>{{ end }}</td></tr>
  </tbody>
</table>

<div style="display:flex; align-items:baseline; gap:0.75rem; margin-top:1.25rem; margin-bottom:0.5rem;">
  <p style="font-size:1.05rem; font-weight:700; margin:0;">Coder health</p>
  <span style="font-size:0.85em; color:#6b7280;">action:</span> {{ if and $installID $dhID }}<a href="./{{ $installID }}/actions/{{ $dhID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">coder_deployment_health</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">coder_deployment_health</code>{{ end }}
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
| `coder_image_tag` | `{{ dig "coder_image_tag" "—" $in }}` | Exact Coder container image tag (e.g. `v2.33.10`). Also drives the `release` label. |

### Vendor-controlled

The vendor pins these in the app config and rolls them with app branches (`nuon branches preview` / `nuon branches trigger`).

| Input | Current value | Description |
|---|---|---|
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

The Coder binary is selected per install via the `coder_image_tag` input (wired to `coder.image.tag` in [`components/values/coder.yaml`](./components/values/coder.yaml)):

```yaml
tag: "{{.nuon.inputs.inputs.coder_image_tag}}"
```

Set the tag **once** in `[[inputs]]`. The `release` label is templated from it — do not hardcode the same string in both places:

```toml
[[inputs]]
coder_image_tag = "v2.33.10"

[labels]
channel = "stable"
release = "{{ .nuon.install.inputs.coder_image_tag }}"
```

Coder’s **Stable** vs **Mainline** words in [release notes](https://github.com/coder/coder/releases) are guidance for picking a tag. They are **not** Nuon app branches. Folders under `installs/` (`mainline/`, `stable/`, `pinned/`) are training cohorts for which customers share a channel — still one Nuon app branch (`main`).

### List recent releases

```sh
gh api "repos/coder/coder/releases?per_page=15" --jq 'sort_by(.published_at) | reverse | .[] | [(.published_at[0:10]), .tag_name, (if (.body // "") | test("mainline Coder release") then "mainline" elif (.body // "") | test("Stable \\(since") then "stable" else "-" end)] | @tsv'
```

Last ten **mainline** (newest first; `*` = used in this app’s install configs):

- `v2.37.3`
- `v2.37.2`
- `v2.37.1`
- `v2.37.0`
- `v2.36.4`
- `v2.36.3` *
- `v2.36.1`
- `v2.36.0`
- `v2.35.2`
- `v2.35.1`

Last ten **stable**:

- `v2.36.6`
- `v2.36.5`
- `v2.35.4`
- `v2.34.6`
- `v2.33.11`
- `v2.33.10` *
- `v2.33.9`
- `v2.33.8` *
- `v2.33.7`
- `v2.32.5`

Sample pins are intentionally several releases back so you can demo an upgrade to a newer tag.

| Cohort | Directory | Installs | `coder_image_tag` | On branch runs? |
|---|---|---|---|---|
| Mainline | `installs/mainline/` | `customer-square`, `customer-dropbox` | `v2.36.3` | Yes (`fleet`+`wave`) |
| Stable | `installs/stable/` | `customer-palantir`, `customer-mercedes-benz`, `customer-kkr` | `v2.33.10` | Yes (`fleet`+`wave`) |
| Pinned | `installs/pinned/` | `customer-discord`, `customer-dod` | `v2.33.8` | No (omit `fleet`/`wave`) |
| Lab | `installs/lab/` | `preview-main` | `v2.36.3` | Yes (`fleet`+`wave=preview`) |

Pinned installs stay on app branch `main` and keep config sync, but they are **not** in install groups — branch preview/trigger skips them. Bump their Coder tag with `installs sync` on that folder or file only.

**Use case:** a customer that must stay on an older Coder release (compliance freeze, slow change window) and should not ride every app-config branch run. They still share `main` for when you *do* want to roll infra/config — you opt them in by adding `fleet`/`wave`, or push a one-off change with `installs sync` on their file. Until then, mainline/stable take the branch-run blast radius; pinned does not.

### Steps (upgrade a cohort)

1. Pick a newer exact tag from the list above (or refresh with `gh api`).
2. Change only `coder_image_tag` in the TOMLs under that channel directory (`release` follows on sync).
3. Sync **that channel** (not the whole tree):

```sh
nuon installs sync -d installs/mainline/ --confirm
nuon installs sync -d installs/stable/ --confirm
nuon installs sync -d installs/pinned/ --confirm

# One pinned customer only
nuon installs sync -d installs/pinned/customer-discord.toml --confirm
```

Avoid `nuon installs sync -d installs/` for routine upgrades — it hits every channel plus `lab/` at once (mixed blast radius). Prefer a channel directory or a single file.

App-config / infra changes still use the Nuon app branch:

```sh
nuon branches preview --branch-id main --git-ref my-feature --mode plan-only
nuon branches trigger --branch-id main
```

> [!WARNING]
> Major Coder upgrades may include database migrations. Migrations run as part of the helm upgrade and are **not separately reversible**. Read the [release notes](https://github.com/coder/coder/releases) before approving.

</nuon-tab>

<nuon-tab name="operations">

<br/>

Installs are managed as code under [`installs/`](./installs), grouped by **channel folder** (mainline / stable / pinned / lab). Docs: [Install Configs](https://docs.nuon.co/guides/install-configs), [app branches](https://docs.nuon.co/concepts/app-branches), [dynamic labels](https://docs.nuon.co/guides/install-configs#dynamic-labels).

App config ships through config-managed app branches:

- `nuon branches sync --file branches/`
- `nuon installs sync -d installs/<channel>/` (or a single file)
- `nuon branches preview` / `nuon branches trigger`

### Bootstrap / edit an install config

1. Copy an example from [`installs/`](./installs) or generate from a live install:
   ```sh
   nuon installs generate-config -i <install-name> > installs/stable/<install-name>.toml
   ```
2. Edit `[labels]`, `approval_option`, `[aws_account]`, or `[[inputs]]` as needed. Keep `release` templated from `coder_image_tag`.
3. Sync the channel directory or one file (see Upgrade tab).

### Nuon app branch vs Coder channel

| Concept | What it is | This sample |
|---|---|---|
| Nuon app branch `main` | Rolls shared app config (components, actions, …) | `branches/main.toml` — preview → installs with `fleet`+`wave` |
| Install folder `mainline/` / `stable/` / `pinned/` | Which Coder binary cohort / how you sync upgrades | Not Nuon app branches |
| Labels `channel` + `release` | Dashboard metadata | `channel` static; `release` from `coder_image_tag` |
| Labels `fleet` + `wave` | Opt into branch-run install groups | On mainline/stable/lab; **omitted** on pinned |

```sh
nuon branches sync --file branches/ --confirm
nuon branches preview --branch-id main --git-ref my-feature --mode plan-only
nuon branches trigger --branch-id main
```

All example installs use `approval_option = "approve-all"` and `app_branch = "main"`. Pinned customers omit `fleet`/`wave` so app-config branch runs skip them; Coder version bumps still use `nuon installs sync` on `installs/pinned/`.

### Opting an install out

Two different knobs:
- **Skip branch runs only** (still config-managed): omit `fleet`/`wave` labels — see `installs/pinned/`.
- **Leave config management entirely**: `nuon installs toggle-sync --disable -i <install-name>` (dashboard-only from then on); `--enable` reverses it.

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

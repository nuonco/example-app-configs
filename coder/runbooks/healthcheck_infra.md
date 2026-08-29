{{ $k8s     := default dict (index (default dict .nuon.actions.workflows) "k8s_status") }}
{{ $coder   := default dict (index (default dict .nuon.actions.workflows) "coder_health") }}
{{ $alb     := default dict (index (default dict .nuon.actions.workflows) "alb_healthcheck") }}
{{ $grafana := default dict (index (default dict .nuon.actions.workflows) "grafana_health") }}
{{ $prom    := default dict (index (default dict .nuon.actions.workflows) "prom_targets") }}

{{ $k8sOut     := default dict (dig "outputs" dict $k8s) }}
{{ $coderOut   := default dict (dig "outputs" dict $coder) }}
{{ $albOut     := default dict (dig "outputs" dict $alb) }}
{{ $grafanaOut := default dict (dig "outputs" dict $grafana) }}
{{ $promOut    := default dict (dig "outputs" dict $prom) }}

{{ $k8sInd   := dig "indicator" "" $k8sOut }}
{{ $coderInd := dig "indicator" "" $coderOut }}
{{ $grafInd  := dig "indicator" "" $grafanaOut }}
{{ $promInd  := dig "indicator" "" $promOut }}

{{ $albCoderMap := default dict (dig "coder" dict $albOut) }}
{{ $albGrafMap  := default dict (dig "grafana" dict $albOut) }}
{{ $albCoder    := dig "indicator" "" $albCoderMap }}
{{ $albGraf     := dig "indicator" "" $albGrafMap }}
{{ $albInd   := "" }}
{{ if and (eq $albCoder "🟢") (eq $albGraf "🟢") }}{{ $albInd = "🟢" }}{{ else if or (eq $albCoder "🔴") (eq $albGraf "🔴") }}{{ $albInd = "🔴" }}{{ end }}

{{ $dh    := default dict (index (default dict .nuon.actions.workflows) "coder_deployment_health") }}
{{ $dhOut := default dict (dig "outputs" dict $dh) }}
{{ $dhInd := dig "indicator" "" $dhOut }}

{{ $anyMissing := or (eq $k8sInd "") (eq $coderInd "") (eq $albInd "") (eq $grafInd "") (eq $promInd "") (eq $dhInd "") }}

<div style="padding-top:1rem;"></div>

End-to-end healthcheck across Kubernetes, Coder, ALB, Grafana, and Prometheus. A green run means: the cluster is healthy, Coder's `/api/v2/buildinfo` responds with a version, both ALB ingresses have a load balancer hostname, Grafana reports `database: ok`, every Prometheus scrape target is up, and Coder's access/DERP/websocket/workspace-proxy paths all respond.

{{ if $anyMissing }}
<nuon-banner theme="warn">One or more sub-checks haven't run yet. Click <strong>Run runbook</strong> at the top right to populate every status.</nuon-banner>
<br/>
{{ end }}

<table>
  <thead>
    <tr><th>#</th><th>Step</th><th>Status</th><th>Action</th><th>What it checks</th></tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>k8s-status</td>
      <td>{{ if eq $k8sInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $k8sInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>k8s_status</code></td>
      <td>Pods, deployments, and nodes in <code>coder</code> and <code>coder-observability</code> namespaces</td>
    </tr>
    <tr>
      <td>2</td>
      <td>coder-health</td>
      <td>{{ if eq $coderInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $coderInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>coder_health</code></td>
      <td><code>/api/v2/buildinfo</code> returns 200 with a <code>version</code></td>
    </tr>
    <tr>
      <td>3</td>
      <td>alb-status</td>
      <td>{{ if eq $albInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $albInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>alb_healthcheck</code></td>
      <td>Both Coder and Grafana ingresses have a load balancer hostname</td>
    </tr>
    <tr>
      <td>4</td>
      <td>grafana-health</td>
      <td>{{ if eq $grafInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $grafInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>grafana_health</code></td>
      <td><code>/grafana/api/health</code> reports <code>database: ok</code></td>
    </tr>
    <tr>
      <td>5</td>
      <td>prom-targets</td>
      <td>{{ if eq $promInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $promInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>prom_targets</code></td>
      <td>Every Prometheus active target reports <code>health: up</code></td>
    </tr>
    <tr>
      <td>6</td>
      <td>coder-deployment-health</td>
      <td>{{ if eq $dhInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $dhInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>coder_deployment_health</code></td>
      <td>Access URL, DERP, websocket, and workspace proxy paths all respond</td>
    </tr>
  </tbody>
</table>

Each step is also runnable on its own from the **Operations** tab. Steps run cheapest-first so a failure in a foundational step short-circuits the rest in a useful way.

### Triage

If a step is red, expand the latest run under the **Run history** tab and look at the action's JSON output:

- **k8s-status** — `pods[*].not_ready` and `deployments[*].under_replicated` name the broken pod or deployment. Hit it with `kubectl describe` from the `troubleshoot` action.
- **coder-health** — non-200 from `/api/v2/buildinfo`. Almost always the ALB or a crashed coder pod.
- **alb-status** — `loadBalancer.ingress[]` is empty. Check the ALB controller deployment in `kube-system`; the ingress's events usually point at a cert or subnet issue.
- **grafana-health** — `database != ok` means the Grafana → RDS path is broken. Grafana/postgres-exporter connect as `coder_exporter` (password auth, not IAM). Usually the `coder-db-password` secret in `coder-observability` is missing or stale — re-run `coder_db_init` from Operations.
- **prom-targets** — the `down[]` array lists each target with `job`, `instance`, and `lastError`. Usually a NetworkPolicy, a crashed scrape target, or a wrong port.
- **coder-deployment-health** — check `probes` in the action output for the raw HTTP status of each path. A red `access_url` usually means the same thing as a red `coder-health`; a red `derp` or `websocket` points at the ALB's WebSocket/idle-timeout settings rather than Coder itself.

For per-subsystem Coder detail beyond this runbook (`database`, `provisioner_daemons`), the Coder owner can open <a href="https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/health">the Coder health page</a> in a browser — gated by their own session login, no API token to mint.

### Notes

- Run after install completes, after upgrades, or whenever you want a single green/red signal before opening dashboards.
- Out of scope: log bundling (use the `troubleshoot` action), ALB external reachability from the public internet (the `coder-health` and `grafana-health` curls cover that path implicitly), workspace-level health, and direct RDS connectivity (Grafana's `database: ok` is the closest proxy signal; there is no standalone IAM-auth database check).

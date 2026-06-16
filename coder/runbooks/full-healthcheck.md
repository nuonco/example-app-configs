{{ $k8s     := default dict (index (default dict .nuon.actions.workflows) "k8s_status") }}
{{ $coder   := default dict (index (default dict .nuon.actions.workflows) "coder_health") }}
{{ $db      := default dict (index (default dict .nuon.actions.workflows) "db_ping") }}
{{ $alb     := default dict (index (default dict .nuon.actions.workflows) "alb_healthcheck") }}
{{ $grafana := default dict (index (default dict .nuon.actions.workflows) "grafana_health") }}
{{ $prom    := default dict (index (default dict .nuon.actions.workflows) "prom_targets") }}

{{ $k8sInd   := dig "outputs" "indicator" "" $k8s }}
{{ $coderInd := dig "outputs" "indicator" "" $coder }}
{{ $dbInd    := dig "outputs" "indicator" "" $db }}
{{ $grafInd  := dig "outputs" "indicator" "" $grafana }}
{{ $promInd  := dig "outputs" "indicator" "" $prom }}

{{ $albCoder := dig "outputs" "coder" "indicator" "" $alb }}
{{ $albGraf  := dig "outputs" "grafana" "indicator" "" $alb }}
{{ $albInd   := "" }}
{{ if and (eq $albCoder "🟢") (eq $albGraf "🟢") }}{{ $albInd = "🟢" }}{{ else if or (eq $albCoder "🔴") (eq $albGraf "🔴") }}{{ $albInd = "🔴" }}{{ end }}

{{ $anyMissing := or (eq $k8sInd "") (eq $coderInd "") (eq $dbInd "") (eq $albInd "") (eq $grafInd "") (eq $promInd "") }}

<div style="padding-top:1rem;"></div>

End-to-end healthcheck across Kubernetes, Coder, RDS, ALB, Grafana, and Prometheus. A green run means: the cluster is healthy, Coder's `/api/v2/buildinfo` responds with a version, RDS accepts a `SELECT 1`, both ALB ingresses have a load balancer hostname, Grafana reports `database: ok`, and every Prometheus scrape target is up.

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
      <td>db-ping</td>
      <td>{{ if eq $dbInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $dbInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>db_ping</code></td>
      <td><code>SELECT 1;</code> against RDS via a throwaway <code>postgres:16-alpine</code> pod</td>
    </tr>
    <tr>
      <td>4</td>
      <td>alb-status</td>
      <td>{{ if eq $albInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $albInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>alb_healthcheck</code></td>
      <td>Both Coder and Grafana ingresses have a load balancer hostname</td>
    </tr>
    <tr>
      <td>5</td>
      <td>grafana-health</td>
      <td>{{ if eq $grafInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $grafInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>grafana_health</code></td>
      <td><code>/grafana/api/health</code> reports <code>database: ok</code></td>
    </tr>
    <tr>
      <td>6</td>
      <td>prom-targets</td>
      <td>{{ if eq $promInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $promInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td>
      <td><code>prom_targets</code></td>
      <td>Every Prometheus active target reports <code>health: up</code></td>
    </tr>
  </tbody>
</table>

Each step is also runnable on its own from the **Operations** tab. Steps run cheapest-first so a failure in a foundational step short-circuits the rest in a useful way.

### Triage

If a step is red, expand the latest run under the **Run history** tab and look at the action's JSON output:

- **k8s-status** — `pods[*].not_ready` and `deployments[*].under_replicated` name the broken pod or deployment. Hit it with `kubectl describe` from the `troubleshoot` action.
- **coder-health** — non-200 from `/api/v2/buildinfo`. Almost always the ALB or a crashed coder pod.
- **db-ping** — the `raw` field has psql's stderr. Common: the `coder-db-url` secret is missing (re-run `coder_rds_creds` from Operations), RDS is down, or the security group is blocking the throwaway pod.
- **alb-status** — `loadBalancer.ingress[]` is empty. Check the ALB controller deployment in `kube-system`; the ingress's events usually point at a cert or subnet issue.
- **grafana-health** — `database != ok` means the Grafana → RDS path is broken. Usually the `coder-db-password` secret in `coder-observability`.
- **prom-targets** — the `down[]` array lists each target with `job`, `instance`, and `lastError`. Usually a NetworkPolicy, a crashed scrape target, or a wrong port.

For per-subsystem Coder detail (`database`, `derp`, `websocket`, `workspace_proxy`, `provisioner_daemons`), the Coder owner can open <a href="https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}/health">the Coder health page</a> in a browser — gated by their own session login, no API token to mint.

### Notes

- Run after install completes, after upgrades, or whenever you want a single green/red signal before opening dashboards.
- Out of scope: log bundling (use the `troubleshoot` action), ALB external reachability from the public internet (the `coder-health` and `grafana-health` curls cover that path implicitly), workspace-level health.

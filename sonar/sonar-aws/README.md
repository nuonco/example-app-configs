{{ $nuonRoot := default dict .nuon }}
{{ $install     := default dict (dig "install" dict $nuonRoot) }}
{{ $installStack := default dict (dig "install_stack" dict $nuonRoot) }}
{{ $actionsMap  := default dict (dig "actions" dict $nuonRoot) }}
{{ $workflows   := default dict (dig "workflows" dict $actionsMap) }}
{{ $installID   := dig "id" "" $install }}

{{ $k8s   := default dict (dig "k8s_status" dict $workflows) }}
{{ $sonar := default dict (dig "sonar_health" dict $workflows) }}
{{ $alb   := default dict (dig "alb_healthcheck" dict $workflows) }}

{{ $k8sOut   := default dict (dig "outputs" dict $k8s) }}
{{ $sonarOut := default dict (dig "outputs" dict $sonar) }}
{{ $albOut   := default dict (dig "outputs" dict $alb) }}

{{ $k8sID   := dig "id" "" $k8s }}
{{ $sonarID := dig "id" "" $sonar }}
{{ $albID   := dig "id" "" $alb }}

{{ $k8sInd   := dig "indicator" "" $k8sOut }}
{{ $sonarInd := dig "indicator" "" $sonarOut }}

{{ $albSonarMap := default dict (dig "sonarqube" dict $albOut) }}
{{ $albSonar    := dig "indicator" "" $albSonarMap }}

{{ $k8sUpdated := dig "updated_at" "" $k8sOut }}
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
{{ $env         := dig "env" "" $labels }}
{{ $previewLbl  := dig "preview" "" $labels }}
{{ $installName := dig "name" "" $install }}
{{ $inEarly     := default dict (dig "inputs" dict $install) }}
{{ $buildNum    := dig "sonarqube_build_number" "26.9.0.129388" $inEarly }}
{{ $releaseLbl  := dig "release" "" $labels }}
{{ if eq $releaseLbl "" }}{{ $releaseLbl = $buildNum }}{{ end }}

<div style="display:flex; width:100%; align-items:center; justify-content:space-between; padding-bottom:1rem;">
  <div>
    <h1 style="margin:0;">SonarQube Community Build</h1>
    <p style="margin:0.4rem 0 0; color:#6b7280;">Code quality and security analysis in your AWS account.</p>
  </div>
  <div style="display:flex; flex-direction:column; gap:10px; align-items:flex-end;">
    <div style="display:flex; gap:10px; align-items:center;">
      {{ if $domain -}}
      <a href="https://{{ $domain }}" style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:#4b6bfb; color:white; border-radius:8px; text-decoration:none; font-weight:600; font-size:15px;">Open SonarQube →</a>
      {{ else -}}
      <span style="display:inline-flex; align-items:center; justify-content:center; gap:8px; padding:10px 22px; background:#4b6bfb; color:white; border-radius:8px; font-weight:600; font-size:15px; opacity:0.55;">Open SonarQube →</span>
      {{ end -}}
    </div>
    <div style="display:flex; flex-direction:column; align-items:flex-end; gap:2px;">
      <nuon-run-runbook name="healthcheck_infra"></nuon-run-runbook>
      {{ with $k8sUpdated }}<span style="font-size:0.75em; color:#6b7280;">Last run <nuon-time time="{{ . }}" format="relative"></nuon-time></span>{{ end }}
    </div>
    <div style="display:flex; flex-direction:column; align-items:flex-end; gap:2px;">
      <nuon-run-runbook name="breakglass_k8s_remediate"></nuon-run-runbook>
      {{ with $bgCleanUpdated }}<span style="font-size:0.75em; color:#6b7280;">Last run <nuon-time time="{{ . }}" format="relative"></nuon-time></span>{{ end }}
    </div>
  </div>
</div>

{{ if not $domain -}}
<nuon-banner theme="warn">
Provisioning in progress — the SonarQube URL appears here when the sandbox DNS record is ready.
</nuon-banner>
{{ else -}}
<nuon-banner theme="success">
SonarQube Community Build for this install. Run <strong>healthcheck_infra</strong> to refresh status (no cron).
</nuon-banner>
{{ end -}}

<br/>

<nuon-group gap="8" align="center">
  {{ if $env }}<nuon-label-badge label="env:{{ $env }}"></nuon-label-badge>{{ end }}
  {{ if eq $previewLbl "true" }}<nuon-label-badge label="preview:true"></nuon-label-badge>{{ end }}
  <nuon-label-badge label="release:{{ $releaseLbl }}"></nuon-label-badge>
  <nuon-badge theme="neutral">sandbox:eks-auto</nuon-badge>
  {{ if $region }}<nuon-badge theme="neutral">{{ $region }}</nuon-badge>{{ end }}
  {{ if $installName }}<nuon-badge theme="neutral">{{ $installName }}</nuon-badge>{{ end }}
</nuon-group>

<br/>

## Getting started

Vendor setup from this app directory (`sonar/sonar-aws`). Leaf dir name = Nuon app slug `sonar-aws`.

Branches-first: Nuon loads config from **git** (`branches/main.toml` → `public_repo`). `nuon branches sync` updates branch settings only; it does not build. Builds/deploys use `nuon branches preview` / `trigger` after you push. `[run].mode = "manual_only"` so pushes do not auto-roll customers.

### First-time

```bash
brew install nuonco/tap/nuon
nuon auth login
cd sonar/sonar-aws
nuon apps create --name sonar-aws
nuon branches sync --file branches/ --confirm
nuon installs sync -d installs/preview.toml --confirm
git push   # public_repo.branch, e.g. mm/sonar
nuon branches preview -a sonar-aws -b main --git-ref mm/sonar --mode apply
```

Start with `preview` only. Add customer installs later with `nuon installs sync -d installs/<name>.toml --confirm`. Open https://app.nuon.co, select **sonar-aws**, and provision the preview install if needed.

### Day-to-day

```bash
# after push
nuon branches preview -a sonar-aws -b main --git-ref mm/sonar --mode build-only --force
nuon branches preview -a sonar-aws -b main --git-ref mm/sonar --mode apply
# ship customers when ready
nuon branches trigger -a sonar-aws -b main
```

Sibling clouds: [Azure](../sonar-azure) · [GCP](../sonar-gcp).

## Health

Status comes from the last run of report actions. Use the healthcheck runbook above — nothing is scheduled on a cron.

<table>
  <thead><tr><th>Check</th><th>Status</th><th>Action</th></tr></thead>
  <tbody>
    <tr><td>Kubernetes</td><td>{{ if eq $k8sInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $k8sInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $k8sID }}<a href="./{{ $installID }}/actions/{{ $k8sID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">k8s_status</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">k8s_status</code>{{ end }}</td></tr>
    <tr><td>SonarQube API</td><td>{{ if eq $sonarInd "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $sonarInd "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $sonarID }}<a href="./{{ $installID }}/actions/{{ $sonarID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">sonar_health</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">sonar_health</code>{{ end }}</td></tr>
    <tr><td>ALB · Sonar ingress</td><td>{{ if eq $albSonar "🟢" }}<nuon-status status="active" variant="badge"></nuon-status>{{ else if eq $albSonar "🔴" }}<nuon-status status="error" variant="badge"></nuon-status>{{ else }}<nuon-status status="pending" variant="badge"></nuon-status>{{ end }}</td><td>{{ if and $installID $albID }}<a href="./{{ $installID }}/actions/{{ $albID }}" style="color:inherit; text-decoration:none;"><code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code></a>{{ else }}<code style="font-size:0.85em; color:#6b7280;">alb_healthcheck</code>{{ end }}</td></tr>
  </tbody>
</table>

<nuon-tabs>
<nuon-tab name="Application">

## Access

- URL: {{ if $domain }}[https://{{ $domain }}](https://{{ $domain }}){{ else }}—{{ end }}
- User: `admin`
- Password: customer secret `admin_password` (Secrets Manager → synced to the cluster)
- Build: `{{ $buildNum }}` → image `sonarqube:{{ $buildNum }}-community`

## Architecture

EKS Auto Mode sandbox, RDS PostgreSQL (password auth via Secrets Manager), official SonarSource Helm chart (`community.enabled`), ACM certificate, ALB ingress. Chart ingress disabled.

<nuon-config-graph></nuon-config-graph>

</nuon-tab>
<nuon-tab name="Upgrade">

## Version pins

`sonarqube_build_number` is an **install input**, not a Nuon app branch.

- Bump build number: sync the install file(s) under `installs/`.
- Infra / app-config changes: trigger app branch `main` (stage install group, then production).

Installs: `preview`, `customer-barclays` (+ `-stage`), `customer-ford` (+ `-stage`).

Lookup Community Build tags:

```bash
gh api 'repos/SonarSource/docker-sonarqube/releases?per_page=50' \
  --jq '.[] | select(.name | test("Community Build")) | "\(.tag_name)\tsonarqube:\(.tag_name)-community"'
```

Install groups on branch `main`: `stage` (`env=stage`) then `production` (`env=prod`).

</nuon-tab>
<nuon-tab name="Operations">

## Day-2

- `healthcheck_infra` — k8s + Sonar API + ALB (manual / runbook only)
- `sonar_rds_creds` — copies RDS master password into K8s secret `sonar-jdbc` (also post-deploy on RDS)
- `sonar_admin_secret` — ensures admin secret has `password` + `currentPassword` keys for the Helm chart
- `troubleshoot` — parameterized kubectl
- `breakglass_k8s_remediate` — clean failed pods, clear ingress finalizers, restart deployments

Docs: [K8s install](https://docs.sonarsource.com/sonarqube-community-build/server-installation/on-kubernetes-or-openshift/) · [Helm chart](https://github.com/SonarSource/helm-chart-sonarqube)

</nuon-tab>
</nuon-tabs>

Sibling clouds: [Azure](../sonar-azure) · [GCP](../sonar-gcp)

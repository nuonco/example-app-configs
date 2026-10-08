{{ $nuonRoot := default dict .nuon }}
{{ $install := default dict (dig "install" dict $nuonRoot) }}
{{ $installStack := default dict (dig "install_stack" dict $nuonRoot) }}
{{ $installID := dig "id" "" $install }}
{{ $sandbox := default dict (dig "sandbox" dict $install) }}
{{ $sbOut := default dict (dig "outputs" dict $sandbox) }}
{{ $nuonDNS := default dict (dig "nuon_dns" dict $sbOut) }}
{{ $pubDomainMap := default dict (dig "public_domain" dict $nuonDNS) }}
{{ $domain := dig "name" "" $pubDomainMap }}
{{ $stackOut := default dict (dig "outputs" dict $installStack) }}
{{ $project := dig "project_id" "" $stackOut }}
{{ $region := dig "region" "" $stackOut }}
{{ $inEarly := default dict (dig "inputs" dict $install) }}
{{ $buildNum := dig "sonarqube_build_number" "26.9.0.129388" $inEarly }}

<center>
<h1>SonarQube Community Build (GCP)</h1>
{{ if $domain }}
<p><a href="https://{{ $domain }}">Open SonarQube</a></p>
{{ else }}
<nuon-banner theme="warn">Public domain not ready yet. Wait for sandbox DNS outputs.</nuon-banner>
{{ end }}
</center>

Nuon Install Id: {{ if $installID }}{{ $installID }}{{ else }}—{{ end }}

GCP Project: {{ if $project }}{{ $project }}{{ else }}—{{ end }}

GCP Region: {{ if $region }}{{ $region }}{{ else }}—{{ end }}

Build: `{{ $buildNum }}` → image `sonarqube:{{ $buildNum }}-community`

## Getting started

Vendor setup from this app directory (`sonar/sonar-gcp`). Leaf dir name = Nuon app slug `sonar-gcp`.

Branches-first: Nuon loads config from **git** (`branches/main.toml` → `public_repo`). `nuon branches sync` updates branch settings only; it does not build. Builds/deploys use `nuon branches preview` / `trigger` after you push. `[run].mode = "manual_only"` so pushes do not auto-roll customers.

### First-time

```bash
brew install nuonco/tap/nuon
nuon auth login
cd sonar/sonar-gcp
nuon apps create --name sonar-gcp
nuon branches sync --file branches/ --confirm
nuon installs sync -d installs/preview.toml --confirm
git push   # public_repo.branch, e.g. mm/sonar
nuon branches preview -a sonar-gcp -b main --git-ref mm/sonar --mode apply
```

Start with `preview` only. Add customer installs later with `nuon installs sync -d installs/<name>.toml --confirm`. Open https://app.nuon.co, select **sonar-gcp**, and provision the preview install if needed.

### Day-to-day

```bash
# after push
nuon branches preview -a sonar-gcp -b main --git-ref mm/sonar --mode build-only --force
nuon branches preview -a sonar-gcp -b main --git-ref mm/sonar --mode apply
# ship customers when ready
nuon branches trigger -a sonar-gcp -b main
```

Sibling clouds: [AWS](../sonar-aws) · [Azure](../sonar-azure).

## Architecture

GKE sandbox (`gcp-gke-sandbox`), Cloud SQL PostgreSQL, official SonarSource Helm chart (`community.enabled`), Certificate Manager, Gateway API (GCLB). Chart ingress disabled.

## Access

- URL: {{ if $domain }}`https://{{ $domain }}`{{ else }}—{{ end }}
- Admin user: `admin` (password from install secret `admin_password`)

## Day-2

- `sonar_db_creds` — copies Cloud SQL password into K8s secret `sonar-jdbc` (also post-deploy on Cloud SQL)
- `sonar_admin_secret` — ensures admin secret has `password` + `currentPassword` keys for the Helm chart

Docs: [K8s install](https://docs.sonarsource.com/sonarqube-community-build/server-installation/on-kubernetes-or-openshift/) · [Helm chart](https://github.com/SonarSource/helm-chart-sonarqube)

Sibling clouds: [AWS](../sonar-aws) · [Azure](../sonar-azure)

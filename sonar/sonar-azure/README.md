{{ $nuonRoot := default dict .nuon }}
{{ $install := default dict (dig "install" dict $nuonRoot) }}
{{ $installID := dig "id" "" $install }}
{{ $sandbox := default dict (dig "sandbox" dict $install) }}
{{ $sbOut := default dict (dig "outputs" dict $sandbox) }}
{{ $pubDomainMap := default dict (dig "public_domain" dict $sbOut) }}
{{ $domain := dig "name" "" $pubDomainMap }}
{{ $inEarly := default dict (dig "inputs" dict $install) }}
{{ $buildNum := dig "sonarqube_build_number" "26.9.0.129388" $inEarly }}
{{ $location := dig "location" "" (default dict (dig "azure" dict (default dict (dig "cloud_account" dict $nuonRoot)))) }}

<center>
<h1>SonarQube Community Build (Azure)</h1>
{{ if $domain }}
<p><a href="https://{{ $domain }}">Open SonarQube</a></p>
{{ else }}
<nuon-banner theme="warn">Public domain not ready yet. Wait for sandbox DNS outputs.</nuon-banner>
{{ end }}
</center>

Nuon Install Id: {{ if $installID }}{{ $installID }}{{ else }}—{{ end }}

Azure Location: {{ if $location }}{{ $location }}{{ else }}—{{ end }}

Build: `{{ $buildNum }}` → image `sonarqube:{{ $buildNum }}-community`

## Getting started

Vendor setup from this app directory (`sonar/sonar-azure`). Leaf dir name = Nuon app slug `sonar-azure`.

Branches-first: Nuon loads config from **git** (`branches/main.toml` → `public_repo`). `nuon branches sync` updates branch settings only; it does not build. Builds/deploys use `nuon branches preview` / `trigger` after you push. `[run].mode = "manual_only"` so pushes do not auto-roll customers.

### First-time

```bash
brew install nuonco/tap/nuon
nuon auth login
cd sonar/sonar-azure
nuon apps create --name sonar-azure
nuon branches sync --file branches/ --confirm
nuon installs sync -d installs/preview.toml --confirm
git push   # public_repo.branch, e.g. mm/sonar
nuon branches preview -a sonar-azure -b main --git-ref mm/sonar --mode apply
```

Start with `preview` only. Add customer installs later with `nuon installs sync -d installs/<name>.toml --confirm`. Open https://app.nuon.co, select **sonar-azure**, and provision the preview install if needed.

### Day-to-day

```bash
# after push
nuon branches preview -a sonar-azure -b main --git-ref mm/sonar --mode build-only --force
nuon branches preview -a sonar-azure -b main --git-ref mm/sonar --mode apply
# ship customers when ready
nuon branches trigger -a sonar-azure -b main
```

Sibling clouds: [AWS](../sonar-aws) · [GCP](../sonar-gcp).

## Architecture

AKS sandbox (`azure-aks-sandbox`), Azure Database for PostgreSQL Flexible Server, official SonarSource Helm chart (`community.enabled`), in-app Application Gateway + AGIC (`ingressClassName: azure-application-gateway`). TLS: cert-manager Let's Encrypt HTTP-01 into Ingress secret `sonarqube-tls`; AGIC syncs that secret onto App Gateway. Chart ingress disabled. Persistence uses `managed-csi` (`disk.csi.azure.com`). Break-glass is Azure Owner on the install resource group.

## Access

- URL: {{ if $domain }}`https://{{ $domain }}`{{ else }}—{{ end }}
- Admin user: `admin` (password from install secret `admin_password`)

## Day-2

- `sonar_db_creds` — copies Flexible Server password into K8s secret `sonar-jdbc` (also post-deploy on postgres)
- `sonar_admin_secret` — ensures admin secret has `password` + `currentPassword` keys for the Helm chart

Docs: [K8s install](https://docs.sonarsource.com/sonarqube-community-build/server-installation/on-kubernetes-or-openshift/) · [Helm chart](https://github.com/SonarSource/helm-chart-sonarqube)

Sibling clouds: [AWS](../sonar-aws) · [GCP](../sonar-gcp)

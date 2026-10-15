# SonarQube (multi-cloud)

SonarQube Community Build is a code quality and security analysis platform. These Nuon app configs install it into the customer's cloud account (BYOC) so source and scan data stay in their VPC, while the vendor still operates the install through Nuon.

## Getting started

Install the Nuon CLI, then create **one app per cloud**. The leaf directory name is the Nuon app slug.

This repo uses a **branches-first** workflow. Nuon loads app config from **git** (the path in `branches/main.toml`). `nuon branches sync` only updates branch settings; it does not build or deploy. Day-to-day builds and deploys use `nuon branches preview` / `nuon branches trigger` after you push.

### First-time setup (per cloud)

```bash
brew install nuonco/tap/nuon
nuon auth login

# AWS — repeat for sonar-azure / sonar-gcp with matching names
cd sonar/sonar-aws
nuon apps create --name sonar-aws
nuon branches sync --file branches/ --confirm
nuon installs sync -d installs/preview.toml --confirm
```

Start with `preview` only so you do not create every customer install at once. Add more later with `nuon installs sync -d installs/<name>.toml --confirm`.

Push this repo’s git ref (see `branches/main.toml` → `public_repo.branch`, e.g. `mm/sonar`), then load config and build from git:

```bash
# builds only (no install deploy)
nuon branches preview -a sonar-aws -b main --git-ref mm/sonar --mode build-only --force

# or build + apply on the preview install (label preview=true)
nuon branches preview -a sonar-aws -b main --git-ref mm/sonar --mode apply
```

Open https://app.nuon.co, select the app, and provision the preview install if it is not up yet.

Do not sync from this parent `sonar/` directory. Azure/GCP: same commands with `-a sonar-azure` / `-a sonar-gcp` and `cd` into that leaf dir.

### Day-to-day (developer loop)

`[run].mode = "manual_only"` — pushes do **not** auto-roll customers.

1. Edit under `sonar/sonar-<cloud>/`.
2. Commit and push a git ref.
3. Iterate on preview:
   - `nuon branches preview -a sonar-<cloud> -b main --git-ref <your-ref> --mode build-only --force` — rebuild components
   - `nuon branches preview -a sonar-<cloud> -b main --git-ref <your-ref> --mode apply` — deploy to the preview install only
4. When ready for customers: `nuon branches trigger -a sonar-<cloud> -b main` (stage then prod install groups).

`nuon branches sync` again only when you change `branches/*.toml` (groups, preview settings, git path). Unpushed local edits are invisible to Nuon without a git ref.

## Layout

Each cloud is a separate Nuon app.

| Cloud | App directory (Nuon app slug) | Sandbox | Cluster / DB / ingress |
| --- | --- | --- | --- |
| AWS | [`sonar-aws/`](sonar-aws/) | [`nuonco/aws-eks-auto-sandbox`](https://github.com/nuonco/aws-eks-auto-sandbox) | EKS Auto Mode, RDS PostgreSQL, ACM + ALB |
| Azure | [`sonar-azure/`](sonar-azure/) | [`nuonco/azure-aks-sandbox`](https://github.com/nuonco/azure-aks-sandbox) | AKS, Azure Database for PostgreSQL Flexible Server, Application Gateway (AGIC) + cert-manager TLS |
| GCP | [`sonar-gcp/`](sonar-gcp/) | [`nuonco/gcp-gke-sandbox`](https://github.com/nuonco/gcp-gke-sandbox) | GKE, Cloud SQL PostgreSQL, Certificate Manager + Gateway API |

Install configs are not shared across clouds. Each uses a cloud-specific account block (`[aws_account]`, `[azure_account]`, or `[gcp_account]`) and cloud-specific DB sizing inputs. Each cloud ships the same install set (`preview`, `customer-barclays`, `customer-barclays-stage`, `customer-ford`, `customer-ford-stage`) with that cloud’s account block.

## What a Nuon sandbox is

In Nuon, a **sandbox** is the Terraform (or equivalent) module that provisions the install's shared infrastructure: Kubernetes cluster, networking, DNS, and often a container registry. App components then deploy into that sandbox.

This is not an AI coding sandbox, agent isolation environment, or local throwaway VM. It is the customer-cloud foundation Nuon creates before your Helm charts and Terraform components run.

## Product links

- [SonarQube Community Build docs (Kubernetes)](https://docs.sonarsource.com/sonarqube-community-build/server-installation/on-kubernetes-or-openshift/)
- [Official Helm chart](https://github.com/SonarSource/helm-chart-sonarqube) (`https://SonarSource.github.io/helm-chart-sonarqube`)
- [Community Build Docker releases](https://github.com/SonarSource/docker-sonarqube/releases)
- [SonarSource Community Edition](https://www.sonarsource.com/products/sonarqube/community-edition/)

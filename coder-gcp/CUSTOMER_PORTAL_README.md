### What this app does?

Coder is a Cloud Development Environment (CDE) platform that enables developers to create, manage, and scale development environments in the cloud. This Nuon app config deploys a production-grade Coder instance on GCP using GKE Autopilot, Cloud SQL Postgres, and a Grafana / Prometheus / Loki observability stack. Review the [Coder docs](https://docs.coder.com) for how it deploys on Kubernetes and visit the [Coder OSS repository](https://github.com/coder/coder) for more information.

### Prerequisites

- GCP project connected to Nuon (handled during onboarding)
- Coder CLI for workspace CLI access ([link to install](https://coder.com/docs/install/cli))

### How to install/What to expect next?

- Clicking install will generate a link for you to log into GCP and run a Cloud Shell-driven Terraform stack which creates the project resources and a runner — an agent that receives jobs to deploy Coder in your project
- If configured, you may be prompted to approve plan steps
- Average installation time is 1 hour due to creating the VPC, GKE Autopilot cluster, Cloud SQL instance, Certificate Manager wildcard, and other app components.

### What gets deployed in your cloud account?

- Dedicated VPC + private services peering range
- GKE Autopilot Kubernetes cluster
- Coder control plane via Helm
- Grafana, Loki and Prometheus via Helm
- Kubernetes logstream via Helm to stream logs into Coder workspace dashboard logs
- GCP Certificate Manager wildcard certificate
- Google Cloud Load Balancer fronted by the Gateway API (`gke-l7-global-external-managed`)
- Cloud DNS records reconciled by `external-dns`

```mermaid

  graph TD

      subgraph Nuon["Nuon Control Plane"]
          NuonAPI["Nuon API"]
      end

      subgraph Clients["Clients"]
          IDE["IDE with SSH"]
          Dashboard["Coder & Grafana Dashboards & Web IDE"]
          IDE ~~~ Dashboard
      end

      subgraph Project["Customer GCP Project"]
          Runner["Nuon Runner"]
          CloudSQL[("Cloud SQL Postgres")]
          CertMgr["Certificate Manager (wildcard)"]
          GCLB["Google Cloud LB (Gateway API)"]
          CloudDNS["Cloud DNS"]

          subgraph GKE["GKE Autopilot Cluster"]
              Coder["Coder"]
              Logstream["Kubelogstream"]
              Observability["Grafana & Prometheus & Loki"]
              ExternalDNS["external-dns"]
              DevEnv["Development Environment"]
          end
      end

      NuonAPI -->|provisions| Runner
      Runner -->|provisions| GKE
      Runner -->|provisions| CloudSQL
      Runner -->|provisions| CertMgr
      Runner -->|provisions| GCLB
      Runner -->|provisions| Coder
      Runner -->|provisions| Logstream
      Runner -->|provisions| Observability
      Runner -->|provisions| ExternalDNS

      CertMgr -->|TLS| GCLB
      GCLB --> Coder
      GCLB --> Observability
      CloudSQL -->|DB| Coder
      Coder --> Observability
      ExternalDNS --> CloudDNS
      Dashboard -->|HTTPS| GCLB
      Coder --> DevEnv
      IDE -->|HTTPS| DevEnv
      IDE -->|HTTPS| GCLB
      Logstream --> DevEnv

```

### What inputs can you enter?

- GCP region
- Coder CLI & API token lifetime
- Coder dashboard session duration
- Block direct (Tailscale DERP) connections from local IDE

### Monitoring and observability

- Grafana (admin password is created in GCP Secret Manager — run the `grafana_password` action to retrieve it)

### Upgrading Coder
- Check [the latest Coder releases](https://github.com/coder/coder/releases/)
- Notify Coder support for a maintenance window to perform an upgrade
- When Coder initiates the upgrade, you will receive approval steps in the customer portal

### Support & escalation

- [support@coder.com](@mailto:support@coder.com)
- [https://docs.coder.com](https://docs.coder.com)

### Security & compliance

- [Nuon BYOC trust center](https://docs.nuon.co/guides/vendor-customers)
- All resource provisioning and scripts are performed by an agent inside your GCP project — no cross-account access granted to Coder
- All secrets created by you or auto-generated and stored in GCP Secret Manager in your project.

### Nuon concepts

The following terminology is core to the Nuon BYOC platform.

#### Connect Your App | App Config
- App (collection of TOML config files that provision and manage the Coder app in your cloud account)
- Sandbox (the underlying infrastructure, in this case GKE Autopilot)
- Component (the Helm charts and Terraform to deploy Coder, Grafana, GCP wildcard certificate, and the Gateway/GCLB)
- Inputs (dynamic values specific to the install e.g., Kubernetes release, Coder release, CLI token lifetime)
- Secrets (sensitive values either auto-created or entered by the customer during Stack creation - stored in GCP Secret Manager)

#### Support Customer Infrastructure | Customer Config

- Installs (Installs are instances of an application in your (the customer) cloud account.)
- Stack (the Terraform install stack that provisions the runner service account, GAR, and Runner agent in your project)
- Runners (Egress-only agents deployed in customer cloud projects that execute all provisioning, deployment, and day-2 operations.)
- Operational Roles (IAM roles to perform different operations for least-privilege access across sandbox, components, and actions.)

#### Continuous Delivery | Day-2 Operations

- Workflows (Orchestration of the deployment, update & teardown lifecycle of apps, components, and actions)
- Actions (Bash scripts for health checks, migrations, debugging, and day-2 operations)
- Policies (Rego & Kyverno configs to enforce compliance and security rules at infrastructure plan steps)
- Customer Portal (A customer-facing web dashboard to initiate and monitor an app's install in a customer's project)

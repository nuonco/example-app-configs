<center>
<h1>GKE Secrets</h1>

Demonstrates Nuon's secrets management on GKE Autopilot — input groups, sensitive inputs, auto-generated platform secrets, and operator-provided secrets synced to Kubernetes.

Nuon Install Id: {{ .nuon.install.id }}

GCP Project: {{ .nuon.install_stack.outputs.project_id }}

</center>

A `secrets-demo` pod boots with four values exercising the four distinct Nuon mechanisms: a non-sensitive input (`greeting`), a sensitive input templated into helm values (`api_key`), an auto-generated platform secret synced into a k8s `Secret` (`auto_generated_token`), and an operator-provided secret captured at install time and synced into a k8s `Secret` (`external_api_token`).

## Architecture

```mermaid

  graph TD

      subgraph Nuon["Nuon Control Plane"]
          NuonAPI["Nuon API"]
          Inputs["Inputs (greeting, api_key)"]
          OpSecret["Operator Secret (external_api_token)"]
          AutoGen["Auto-Generated Secret (auto_generated_token)"]
      end

      subgraph Project["Customer GCP Project"]
          Runner["Nuon Runner"]
          SM["GCP Secret Manager"]

          subgraph GKE["GKE Autopilot Cluster"]
              subgraph NS["secrets-demo namespace"]
                  ExtSec["Secret: external-api-token"]
                  TokSec["Secret: auto-generated-token"]
                  Pod["secrets-demo Pod"]
              end
          end
      end

      NuonAPI -->|provisions| Runner
      Inputs -->|template values| Runner
      OpSecret --> SM
      AutoGen --> SM
      Runner -->|installs helm| Pod
      Runner -->|syncs| ExtSec
      Runner -->|syncs| TokSec
      SM --> Runner
      Inputs -->|env GREETING + API_KEY| Pod
      ExtSec -->|env EXTERNAL_TOKEN| Pod
      TokSec -->|env AUTO_TOKEN| Pod

```

## Components

- **secrets_demo** — Helm chart that deploys a single pod consuming four env vars: `GREETING` (non-sensitive input, templated), `API_KEY` (sensitive input, templated), `AUTO_TOKEN` (auto-generated secret from k8s `Secret`), and `EXTERNAL_TOKEN` (operator-provided secret from k8s `Secret`)

## Inputs and Input Groups

| Group | Input | Sensitive | Description |
|---|---|---|---|
| `app` | `greeting` | no | Greeting message displayed by the demo pod (default `Hello from Nuon`) |
| `credentials` | `api_key` | yes | Sensitive value templated directly into the pod's environment |

## Secrets

| Secret | Source | K8s Secret |
|---|---|---|
| `auto_generated_token` | `auto_generate = true` — install-stack random_password in GCP Secret Manager | `secrets-demo/auto-generated-token` |
| `external_api_token` | `required = true` — operator-provided at install time, stored in GCP Secret Manager | `secrets-demo/external-api-token` |

Both use `kubernetes_sync = true` to materialize values as Kubernetes `Secret` resources in the `secrets-demo` namespace.

## Prerequisites

Enable these GCP APIs on the target project:

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  --project={{ .nuon.install_stack.outputs.project_id }}
```

`container.googleapis.com` is required for the GKE Autopilot cluster.

## Actions

- **verify_secrets** — lists and describes the synced `Secret` resources (auto-runs after `secrets_demo` deploys)
- **read_greeting** — execs into the pod and prints `GREETING`, plus a present/absent check for `API_KEY`, `AUTO_TOKEN`, and `EXTERNAL_TOKEN`
- **post_secrets_sync** — restarts the deployment after every full deploy so the pod picks up rotated secrets

## Resources

- [Nuon Secrets Documentation](https://github.com/nuonco/nuon/tree/main/docs)
- [gcp-gke-sandbox](https://github.com/nuonco/gcp-gke-sandbox)

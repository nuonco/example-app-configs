<center>
<h1>GKE Secrets</h1>

Demonstrates Nuon's secrets management on GKE Autopilot — input groups, sensitive inputs, auto-generated platform secrets, and one-way Kubernetes secret sync.

Nuon Install Id: {{ .nuon.install.id }}

GCP Project: {{ .nuon.install_stack.outputs.project_id }}

</center>

A `secrets-demo` pod boots with a plaintext greeting (from a regular input), an operator-provided API key (sensitive input synced into a `Secret`), and a Nuon-auto-generated token (synced into a separate `Secret`). Use it as a reference when wiring inputs and secrets into your own app config.

## Architecture

```mermaid

  graph TD

      subgraph Nuon["Nuon Control Plane"]
          NuonAPI["Nuon API"]
          Inputs["Inputs (greeting, api_key)"]
          AutoGen["Auto-Generated Secret"]
      end

      subgraph Project["Customer GCP Project"]
          Runner["Nuon Runner"]

          subgraph GKE["GKE Autopilot Cluster"]
              subgraph NS["secrets-demo namespace"]
                  ApiSec["Secret: api-key-secret"]
                  TokSec["Secret: auto-generated-token"]
                  Pod["secrets-demo Pod"]
              end
          end
      end

      NuonAPI -->|provisions| Runner
      Runner -->|installs helm| Pod
      Inputs -->|values + sensitive| Runner
      AutoGen -->|generated| Runner
      Runner -->|syncs| ApiSec
      Runner -->|syncs| TokSec
      ApiSec -->|env API_KEY| Pod
      TokSec -->|env AUTO_TOKEN| Pod

```

## Components

- **secrets_demo** — Helm chart that deploys a single pod consuming `GREETING` (input value), `API_KEY` (sensitive input synced to k8s `Secret`), and `AUTO_TOKEN` (auto-generated Nuon secret synced to k8s `Secret`)

## Inputs and Input Groups

| Group | Input | Sensitive | Description |
|---|---|---|---|
| `app` | `greeting` | no | Greeting message displayed by the demo pod (default `Hello from Nuon`) |
| `credentials` | `api_key` | yes | API key provided by the install operator |

## Secrets

| Secret | Source | K8s Secret |
|---|---|---|
| `auto_generated_token` | `auto_generate = true` (platform-generated) | `secrets-demo/auto-generated-token` |
| `api_key_secret` | `input_name = "api_key"` (sync from sensitive input) | `secrets-demo/api-key-secret` |

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
- **read_greeting** — execs into the pod and prints `GREETING`, plus a present/absent check for `API_KEY` and `AUTO_TOKEN`
- **post_secrets_sync** — restarts the deployment after every full deploy so the pod picks up rotated secrets

## Resources

- [Nuon Secrets Documentation](https://github.com/nuonco/nuon/tree/main/docs)
- [gcp-gke-sandbox](https://github.com/nuonco/gcp-gke-sandbox)

# GKE Simple

Whoami deployment on GCP GKE Autopilot with managed SSL certificate and GKE Ingress. Equivalent to `eks-simple` for AWS.

## Components

- **whoami** — simple HTTP service (helm chart)
- **certificate** — GCP Managed SSL Certificate (terraform module)
- **ingress** — GKE Ingress with Google Cloud Load Balancer (helm chart)

## Resources

- GKE Autopilot cluster via [gcp-gke-sandbox](https://github.com/nuonco/gcp-gke-sandbox)
- Artifact Registry for container images
- Cloud DNS zones (public + internal)
- GCP Managed SSL Certificate
- GKE Ingress (Google Cloud Load Balancer)

## Prerequisites

Enable these GCP APIs on the target project:

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  dns.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=<PROJECT_ID>
```

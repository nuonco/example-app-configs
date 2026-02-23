# GKE Simple

Whoami deployment on GCP GKE Autopilot. Equivalent to `eks-simple` for AWS.

## Resources

- GKE Autopilot cluster via [gcp-gke-sandbox](https://github.com/nuonco/gcp-gke-sandbox)
- Artifact Registry for container images
- Whoami helm chart deployment

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

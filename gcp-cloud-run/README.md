# GCP Cloud Run

A managed container deployment on Google Cloud Run without Kubernetes overhead. Also provisions a GCS bucket and object via Pulumi to demonstrate multi-runtime components.

## Components

- **container_image** — mirrors `containous/whoami:latest` into Artifact Registry
- **cloud_run** — Cloud Run v2 service with public (`allUsers`) invoker access (terraform module)
- **pulumi_gcs_bucket** — GCS bucket (pulumi, go runtime)
- **pulumi_gcs_object** — sample object placed in the bucket (pulumi, go runtime)

## Resources

- Minimal GCP sandbox via [gcp-min-sandbox](https://github.com/nuonco/gcp-min-sandbox)
- Artifact Registry for container images
- Cloud Run v2 service
- GCS bucket and object

## Prerequisites

Enable these GCP APIs on the target project:

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  storage.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=<PROJECT_ID>
```

`run.googleapis.com` is required for the Cloud Run service deployment.

## Configuration

| Input | Default | Description |
|---|---|---|
| `region` | `us-central1` | GCP region for Cloud Run deployment |

## Actions

- **curl_endpoint** — curls the Cloud Run service URL
- **service_status** — describes the deployed Cloud Run service via `gcloud`
- **post-deploy-smoke-test** — post-deploy validation

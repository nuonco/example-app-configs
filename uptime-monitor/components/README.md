# Components

Components are the building blocks of your Nuon app. Each component represents a deployable unit - container images, Helm charts, Kubernetes manifests, or Terraform modules.

## Component Types

| Type                  | Description                            | Use Case                            |
|-----------------------|----------------------------------------|-------------------------------------|
| `docker_build`        | Builds Docker images from Dockerfiles  | Custom application images           |
| `container_image`     | References pre-built container images  | Third-party or pre-built images     |
| `helm_chart`          | Deploys Helm charts                    | Packaged Kubernetes applications    |
| `kubernetes_manifest` | Deploys raw Kubernetes YAML            | Custom K8s resources                |
| `terraform_module`    | Runs Terraform modules                 | Cloud infrastructure (RDS, S3, IAM) |

## Components in This App

### Images (Prefix: 0-)

| Component          | Type           | Description                    |
|--------------------|----------------|--------------------------------|
| `0-api-image.toml` | docker_build   | Builds the API container image |
| `0-ui-image.toml`  | docker_build   | Builds the UI container image  |

### Infrastructure (Prefix: 1-)

| Component      | Type             | Description                              |
|----------------|------------------|------------------------------------------|
| `1-s3.toml`    | terraform_module | S3 bucket for file storage               |
| `1-rds.toml`   | terraform_module | PostgreSQL RDS instance                  |
| `1-irsa.toml`  | terraform_module | IAM role for Kubernetes service accounts |

### Deployments (Prefix: 2-)

| Component      | Type                | Description                |
|----------------|---------------------|----------------------------|
| `2-api.toml`   | kubernetes_manifest | API deployment and service |
| `2-ui.toml`    | kubernetes_manifest | UI deployment and service  |

### Additional Services (Prefix: 3+)

| Component          | Type                | Description                       |
|--------------------|---------------------|-----------------------------------|
| `3-headlamp.toml`  | helm_chart          | Kubernetes dashboard              |
| `4-alb.toml`       | kubernetes_manifest | Application Load Balancer ingress |

## Deployment Order

Components are deployed based on their dependencies. The numeric prefix indicates the general deployment tier:

```
0-*  Images are built first (no dependencies)
 │
 ├── 1-s3, 1-rds  Infrastructure components
 │        │
 │        └── 1-irsa  (depends on s3, rds)
 │              │
 └──────────────┼── 2-api  (depends on api_image, rds, s3, irsa)
                │     │
                │     └── 2-ui  (depends on ui_image, api)
                │           │
                └───────────┴── 3-headlamp
                                    │
                                    └── 4-alb  (depends on ui, headlamp)
```

## Referencing Component Outputs

Components can reference outputs from other components using template variables:

```toml
# Reference a Terraform output
bucket_name = "{{ .nuon.components.s3.outputs.bucket_name }}"

# Reference a Docker image
image = "{{ .nuon.components.api_image.outputs.image.repository }}:{{ .nuon.components.api_image.outputs.image.tag }}"

# Reference sandbox outputs
vpc_id = "{{ .nuon.install.sandbox.outputs.vpc.id }}"
```

## Documentation

- [Components Overview](https://docs.nuon.co/concepts/components)
- [Terraform Components](https://docs.nuon.co/guides/terraform-components)
- [Helm Components](https://docs.nuon.co/guides/helm-components)
- [Kubernetes Manifest Components](https://docs.nuon.co/guides/kubernetes-manifest-components)
- [Docker Build Components](https://docs.nuon.co/guides/docker-build-components)

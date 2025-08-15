# Nuon App Config: Coder on EKS

The App Config is meant for demonstration purposes only with an eye on saving cloud compute costs. It deploys a minimal Coder instance on AWS using Amazon EKS, suitable for development and testing.
---

This configuration deploys Coder on an EKS cluster using Nuon. It provisions:
- A minimal EKS cluster (2x t3.medium nodes)
- Bitnami Postgres for Coder
- Coder via Helm chart
- ALB for external access
- Certificate via cert-manager

## Components
- `1-coder-db.toml`: Bitnami Postgres Helm chart
- `2-coder.toml`: Coder Helm chart
- `3-certificate.toml`: TLS certificate
- `4-alb.toml`: Application Load Balancer for Coder

## Actions
- `gp2-default-storage-class.toml`: Sets the default storage class to gp2
- `create_db_secret.toml`: Creates the Coder DB URL secret in the cluster
- `simple_action.toml`: A simple action to check the cluster, pods and deployment's health

## How it works
1. EKS cluster is created with a small node group
2. Postgres is installed in the `coder` namespace
3. A secret with the DB URL is created
4. Coder is installed and configured to use the DB
5. ALB exposes Coder externally

---


# AKS Simple

Whoami deployment on Azure AKS with Application Gateway Ingress. Equivalent to `eks-simple` for AWS and `gke-simple` for GCP.

## Components

- **whoami** — simple HTTP service (helm chart)
- **ingress** — Azure Application Gateway Ingress via AGIC (helm chart)

## Resources

- AKS cluster via [azure-aks-sandbox](https://github.com/nuonco/azure-aks-sandbox)
- Azure Container Registry for container images
- Azure DNS zones (public + internal)
- Application Gateway (provisioned by AKS sandbox via AGIC add-on)

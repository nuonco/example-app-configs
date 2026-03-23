# AKS Simple

Whoami deployment on Azure AKS with Application Gateway Ingress. Equivalent to `eks-simple` for AWS and `gke-simple` for GCP.

## Components

- **whoami** — simple HTTP service (helm chart)
- **certificate** — cert-manager + Let's Encrypt TLS via Azure DNS (terraform)
- **ingress** — Azure Application Gateway Ingress with TLS via AGIC (helm chart)

## Resources

- AKS cluster via [azure-aks-sandbox](https://github.com/nuonco/azure-aks-sandbox)
- Azure Container Registry for container images
- Azure DNS zones (public + internal)
- Application Gateway (provisioned by AKS sandbox via AGIC add-on)
- cert-manager with Workload Identity for DNS-01 challenges

## Accessing the App

Once deployed, the app URL is available as a component output:

```
{{.nuon.components.certificate.outputs.app_url}}
```

Or visit: `https://<sub_domain>.<public_domain>`

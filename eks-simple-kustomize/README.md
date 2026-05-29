> [!WARNING]
> **Experimental** — this sample app config is a work in progress and is not
> guaranteed to deploy successfully. Use it as a reference only.

# EKS Simple Kustomize

A simple Kustomize-based app config deploying the Argo CD example guestbook application on AWS EKS.

## Components

- **kustomizeapp** — Kubernetes manifest component using Kustomize to deploy `kustomize-guestbook` from `argoproj/argocd-example-apps`.

# EKS Simple Kustomize

A simple Kustomize-based app config deploying the Argo CD example guestbook application on AWS EKS.

## Components

- **kustomizeapp** — Kubernetes manifest component using Kustomize to deploy `kustomize-guestbook` from `argoproj/argocd-example-apps`.

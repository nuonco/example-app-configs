# Dragonfly on Nuon

[Dragonfly](https://dragonflydb.io) is a Redis- and Memcached-API-compatible in-memory data store. This Nuon app config deploys a standalone Dragonfly instance into a customer's AWS account via the official Kubernetes operator: the cache runs in the customer's EKS cluster and is reachable in-cluster only.

## What This Deploys

- EKS Auto Mode cluster (`nuonco/aws-eks-auto-sandbox`)
- S3 bucket with KMS encryption + IRSA — destination for periodic snapshot backups
- Dragonfly operator (Helm) in `dragonfly-operator-system`
- Dragonfly CR (`dragonflydb.io/v1alpha1`) in `dragonfly` namespace

## Connection

In-cluster apps connect via `redis://dragonfly.dragonfly.svc.cluster.local:6379`. With `auth_enabled=true`, the AUTH password is in the `dragonfly-auth` secret in the `dragonfly` namespace. Run the `connection_info` action for a copy-paste-friendly summary.

## Install

```bash
brew install nuonco/tap/nuon
nuon auth login
nuon apps create --name dragonfly
nuon apps sync
```

Then install via the Nuon dashboard at https://app.nuon.co.

## Notes

- Defaults are demo-sized: single replica, no auth, no TLS. Flip `replicas`, `auth_enabled`, `tls_enabled` at install time.
- Snapshots write directly to S3 via IRSA on the `dragonfly` ServiceAccount. PVC backups are not configured.
- Restoring a snapshot is destructive — the `restore_from_snapshot` action requires `CONFIRM=YES`.
- License: Dragonfly is source-available under BSL 1.1 (converts to Apache 2.0 on 2030-07-01). Review the license terms before packaging this for production BYOC use.

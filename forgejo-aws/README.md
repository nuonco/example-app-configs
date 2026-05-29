> [!WARNING]
> **Experimental** — this sample app config is a work in progress and is not
> guaranteed to deploy successfully. Use it as a reference only.

<center>
<h1>Forgejo (AWS)</h1>

Self-hosted git forge on AWS EKS. **Three Pulumi (Go) components** provision the managed data layer — object storage, primary database, and cache — alongside the in-cluster app:

- **`pulumi_s3`** — S3 bucket for LFS/attachments/packages + IRSA role bound to Forgejo's ServiceAccount
- **`pulumi_rds`** — RDS Postgres (private-subnetted, EKS-only SG ingress, generated password)
- **`pulumi_redis`** — ElastiCache Redis (single node) for sessions, queues, and cache

A sibling app config, **`forgejo-gcp`**, mirrors the same shape on GKE using Cloud SQL, Memorystore, and GCS.

Nuon Install Id: {{ .nuon.install.id }}

Public URL: [https://{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}](https://{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }})

</center>

## Architecture

```mermaid
graph TD
    subgraph Nuon["Nuon Control Plane"]
        NuonAPI["Nuon API"]
    end

    subgraph VPC["Customer AWS VPC"]
        Runner["Nuon Runner"]
        subgraph EKS["EKS Cluster"]
            Forgejo["Forgejo Pod<br/>(StatefulSet-style Deployment)"]
            PVC[("Repo PVC<br/>(EBS gp3)")]
            ALB["ALB Ingress<br/>(HTTPS :443)"]
            NLB["NLB Service<br/>(SSH :22)"]
        end
        S3[("S3 Bucket<br/>LFS · attachments · packages")]
        RDS[("RDS Postgres<br/>private subnet")]
        Redis[("ElastiCache Redis<br/>private subnet")]
    end

    NuonAPI -->|provisions| Runner
    Runner -->|pulumi up| S3
    Runner -->|pulumi up| RDS
    Runner -->|pulumi up| Redis
    Runner -->|helm install| Forgejo
    Forgejo -->|IRSA| S3
    Forgejo --> RDS
    Forgejo --> Redis
    Forgejo --> PVC
    ALB --> Forgejo
    NLB --> Forgejo
```

## Components

| # | Component | Type | Purpose |
|---|---|---|---|
| 1 | `pulumi_s3` | pulumi (go) | S3 bucket + IRSA role |
| 2 | `pulumi_rds` | pulumi (go) | RDS Postgres + SG + password |
| 3 | `pulumi_redis` | pulumi (go) | ElastiCache Redis + SG |
| 4 | `forgejo_db_secret` | kubernetes_manifest | Render RDS outputs into k8s Secret |
| 5 | `forgejo_cache_secret` | kubernetes_manifest | Render Redis outputs into k8s Secret |
| 6 | `forgejo_s3_secret` | kubernetes_manifest | Render S3 outputs into k8s Secret |
| 7 | `forgejo` | helm_chart | Forgejo Deployment, Service, PVC, ServiceAccount (IRSA) |
| 8 | `certificate` | terraform_module | ACM certificate (DNS-validated) |
| 9 | `application_load_balancer` | helm_chart | ALB Ingress (HTTPS) |
| 10 | `forgejo_ssh_lb` | kubernetes_manifest | NLB Service exposing git-over-SSH on :22 |

## Configuration

Editable any time from **Manage → Edit Inputs** in the Nuon dashboard.

### Application
| Input | Default | Description |
|---|---|---|
| `forgejo_image` | `codeberg.org/forgejo/forgejo:10.0.1` | Forgejo image |
| `forgejo_admin_user` | `forgejo-admin` | Initial admin username |
| `forgejo_admin_email` | `admin@example.com` | Initial admin email |
| `repo_storage_gb` | `50` | Repo PVC size |

### Database (RDS Postgres)
| Input | Default | Description |
|---|---|---|
| `db_instance_class` | `db.t4g.small` | RDS instance class |
| `db_storage_gb` | `20` | RDS allocated storage |

### Cache (ElastiCache Redis)
| Input | Default | Description |
|---|---|---|
| `redis_node_type` | `cache.t4g.micro` | Redis node type |

### Compute (EKS)
| Input | Default | Description |
|---|---|---|
| `instance_type` | `t3a.medium` | Node instance type |
| `min_size` / `desired_size` / `max_size` | `2 / 2 / 4` | Node group sizing |

## Notes for the Pulumi components

- Pulumi state is persisted by the Nuon runner — no `Pulumi.<stack>.yaml` is committed, and no backend configuration is required in the Go programs.
- `[config]` blocks in each component TOML map to Pulumi stack config (`aws:region`).
- `[env_vars]` blocks pass install/sandbox values into each program at execution time.
- The S3 IRSA trust policy is pinned to `system:serviceaccount:forgejo:forgejo` — matching the ServiceAccount name in `src/helm/forgejo/templates/serviceaccount.yaml`.

## Sibling

See [`forgejo-gcp/`](../forgejo-gcp) for the GKE / Cloud SQL / Memorystore / GCS variant.

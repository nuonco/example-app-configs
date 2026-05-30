Langfuse Access URL: [https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

## Getting Started

[Langfuse](https://langfuse.com) is an open-source LLM observability and tracing platform. Your install runs full-plane in your AWS account — every component (web, worker, Postgres, ClickHouse, Keeper, Valkey, S3) lives in your VPC with no tether back to Langfuse Cloud.

Open the Langfuse Access URL above and sign in with the headless-init admin user.

**To retrieve your admin credentials:**

1. In the Nuon dashboard, go to this install
2. Open the **Actions** tab
3. Run the `admin_password` action
4. The output displays the URL, email (`admin@langfuse.local`), and the generated password

The `admin_password` action also runs automatically post-deploy, so the credentials appear in the install's workflow output the first time langfuse comes up.

The org (`Demo Organization`), project (`Demo Project`), and a starter public/secret API key pair are also pre-seeded by the headless init — see `LANGFUSE_INIT_*` env vars in `components/values/langfuse.yaml`.

## Verify with a Real Trace

The `seed_demo_traces` action runs a small tool-using Claude agent against this install's Langfuse API and writes a real trace tree.

1. Set `anthropic_api_key` on the install (**Manage → Edit Inputs**).
2. Run the action: **Actions → `seed_demo_traces` → Run**.
3. Open the Langfuse Access URL, log in, navigate to `Demo Project` → Traces. The agent run should appear within seconds.

## Architecture

```mermaid
graph TD
    subgraph Nuon["Nuon Control Plane"]
        NuonAPI["Nuon API"]
    end

    subgraph Clients["Clients"]
        Browser["Browser (Langfuse UI)"]
        SDK["SDKs / OTel exporters"]
        Browser ~~~ SDK
    end

    subgraph VPC["Customer Cloud VPC (AWS)"]
        Runner["Nuon Runner"]
        RDS[("PostgreSQL RDS")]
        Valkey[("ElastiCache Valkey")]
        S3[("S3 Bucket")]
        ACM["ACM Certificate"]
        ALB["Application Load Balancer"]
        Stack["CloudFormation Stack"]

        subgraph EKS["EKS Cluster"]
            Web["langfuse-web"]
            Worker["langfuse-worker"]
            CH["ClickHouse"]
            Keeper["ClickHouse Keeper"]
        end
    end

    NuonAPI -->|generates| Stack
    Stack -->|provisions| Runner
    Runner -->|provisions| EKS
    Runner -->|provisions| RDS
    Runner -->|provisions| Valkey
    Runner -->|provisions| S3
    Runner -->|provisions| ACM
    Runner -->|provisions| ALB

    ACM -->|TLS| ALB
    ALB --> Web
    Browser -->|HTTPS| ALB
    SDK -->|HTTPS| ALB
    Web --> RDS
    Web --> CH
    Web --> Valkey
    Web --> S3
    Worker --> RDS
    Worker --> CH
    Worker --> Valkey
    Worker --> S3
    CH --> Keeper
```

## Configuration

The following inputs can be changed at any time from **Manage → Edit Inputs** in the Nuon dashboard.

| Input | Default | Description |
|---|---|---|
| `anthropic_api_key` | _(empty)_ | Anthropic API key used by the `seed_demo_traces` action to generate a real trace tree |
| `telemetry` | `true` | Send anonymized usage telemetry to Langfuse |
| `license_key` | _(empty)_ | Langfuse Enterprise license key (optional; OSS features work without it) |
| `web_replicas` | `2` | Number of `langfuse-web` pods |
| `worker_replicas` | `2` | Number of `langfuse-worker` pods |
| `langfuse_db_instance_type` | `db.t4g.micro` | RDS Postgres instance class |
| `langfuse_db_storage_gb` | `20` | RDS Postgres allocated storage (GB) |
| `clickhouse_replicas` | `1` | ClickHouse cluster replica count (single-shard only — scale vertically, not by sharding) |
| `clickhouse_disk_size` | `20Gi` | ClickHouse pod EBS volume size |

Changing inputs triggers a redeploy of the affected components. The workflow shows a diff and pauses for approval before applying.

## What This Deploys

- EKS Auto Mode cluster (`nuonco/aws-eks-auto-sandbox`)
- RDS PostgreSQL (single instance) — transactional store: users, orgs, projects, encrypted API keys
- ClickHouse cluster (Altinity operator, single-shard, replicated) — OLAP store: traces, observations, scores
- ClickHouse Keeper (vanilla StatefulSet, single node) — raft coordination for replicated tables
- ElastiCache Valkey (`cache.t4g.micro`, single node) — BullMQ queue + cache, `maxmemory-policy=noeviction`
- S3 bucket with KMS encryption + IRSA — raw event payloads, multimodal media, batch exports
- Langfuse Helm release — `langfuse-web` and `langfuse-worker` deployments
- ALB + ACM certificate — public HTTPS access to the Langfuse UI and API

## Sizing

This app config is shaped for fast, low-cost demo provisioning. Defaults trade HA and headroom for shorter install times (~25–35 min on a fresh AWS account) and the lowest possible AWS bill — smallest instance classes, single-AZ, single-replica everywhere, no provisioned IOPS, no premium features. A demo install at idle runs in the low single-digit dollars per day; production sizing (next section) is materially more. Concrete current values:

| Component | Demo Default | Why |
|---|---|---|
| RDS Postgres | `db.t4g.micro`, 20 GB, no multi-AZ, 7-day backups | smallest free-tier-eligible Postgres |
| ClickHouse | 1 replica × 1 shard × 20 Gi EBS gp3 | single-node, no replication overhead |
| ClickHouse Keeper | 1 replica × 5 Gi EBS gp3 | no raft quorum, fastest to provision |
| ElastiCache Valkey | `cache.t4g.micro`, 1 node, no TLS, no auth | smallest Valkey node, security via private subnet + SG |
| Langfuse web / worker | 2 / 2 replicas | minimum for rolling deploys |
| S3 | no lifecycle, no versioning | demo retention only |

### Scaling for production

Recommended changes when moving past demo:

- **RDS Postgres** (knobs are inputs): bump `langfuse_db_instance_type` to `db.r6g.large` or larger based on org/project count, `langfuse_db_storage_gb` to 100+, enable multi-AZ and longer backup retention in the TF, turn on deletion protection.
- **ClickHouse** (knobs are inputs): still single-shard (Langfuse hard requirement — do not shard), but raise `clickhouse_replicas` to 3 for HA and `clickhouse_disk_size` to 100Gi+. Consider pinning the CH pod to a ClickHouse-optimized EC2 family via a dedicated node pool.
- **ClickHouse Keeper** (manifest edit): scale `replicas` in `components/manifests/clickhouse_keeper.yaml` to 3 for raft quorum HA, bump the volume claim to 10 Gi. Don't forget to scale the `zookeeper.nodes` list in `clickhouse_cluster.yaml` to match.
- **ElastiCache Valkey** (TF edit): switch to `cache.r6g.large`+, enable `transit_encryption_enabled` + `auth_token` in `src/components/elasticache_redis/main.tf`, add a replica with multi-AZ failover. Wire the auth token through to Langfuse via the helm values' `redis.auth` block.
- **Langfuse** (knobs are inputs): scale `web_replicas` to match query load and `worker_replicas` to match trace ingest rate — start 5/5 and tune from Langfuse's `/metrics` endpoint.
- **S3** (TF edit): add lifecycle rules for old event payloads (e.g. `events/` → Glacier after 90 days, expire after 365). Enable versioning if compliance requires it.
- **Monitoring**: Langfuse exposes Prometheus metrics on `/metrics`; ClickHouse + Keeper expose them on port 7000. Wire to your existing Prometheus stack, or add a Grafana component (see the coder app config in this repo for an example pattern).
- **Backups**: RDS auto-backups are already enabled. For ClickHouse, add the [clickhouse-backup](https://github.com/Altinity/clickhouse-backup) operator or schedule EBS snapshots of the CH PVCs.

## Notes

- ClickHouse is deployed via the [Altinity clickhouse-operator](https://github.com/Altinity/clickhouse-operator), but Keeper is deployed as a vanilla StatefulSet — the operator's `ClickHouseKeeperInstallation` reconciler is incomplete in current chart versions and creates the surrounding resources but never the StatefulSet itself.
- Langfuse only supports single-shard ClickHouse clusters; scale vertically by raising replica count and disk size, not by sharding.
- `ENCRYPTION_KEY`, `NEXTAUTH_SECRET`, and `SALT` are generated by an install-time action and persisted in `langfuse-secrets`. Re-running the action is idempotent — it does not rotate keys, since rotating `ENCRYPTION_KEY` would break encrypted column reads.
- Postgres, ClickHouse, and Redis/Valkey all run UTC (a Langfuse requirement).
- ElastiCache Valkey runs without auth or TLS; security is the private subnet + SG ingress restriction. For production, enable `transit_encryption` and `auth_token` in the TF module and wire `existingSecret` into the helm values.

## Resources

[Langfuse Documentation](https://langfuse.com/docs)

[Langfuse Self-Hosting Guide](https://langfuse.com/self-hosting)

[Langfuse Helm Chart](https://github.com/langfuse/langfuse-k8s)

[Langfuse GitHub](https://github.com/langfuse/langfuse)

[Anthropic API Console](https://console.anthropic.com)

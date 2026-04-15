<center>
<h1> EKS Karpenter Image Cache </h1>
EKS cluster with Karpenter and pre-cached container images via EBS snapshots.
Large images are pulled once into an EBS snapshot during provisioning, then mounted on every new Karpenter node so pods start instantly without registry pulls.

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

</center>

## How It Works

1. The `image_cache` Terraform component launches a temporary EC2 instance, pulls the specified container images, and creates an EBS snapshot.
2. The `node_class` component creates a Karpenter EC2NodeClass that mounts the snapshot as a secondary volume via `blockDeviceMappings`.
3. On node boot, `userData` copies the cached containerd data before the EKS bootstrap starts containerd.
4. The `node_pool` component creates a Karpenter NodePool referencing the cached EC2NodeClass.
5. Workload pods (e.g. `whoami`) are scheduled on cached nodes with images already available.

## Architecture

```mermaid

  graph TD

      subgraph Nuon["Nuon Control Plane"]
          NuonAPI["Nuon API"]
      end

      subgraph VPC["Customer Cloud VPC (AWS)"]
          Runner["Nuon Runner"]
          Stack["CloudFormation Stack"]

          subgraph EKS["EKS Cluster"]
              subgraph Karpenter["Karpenter"]
                  EC2NodeClass["EC2NodeClass (cached)"]
                  NodePool["NodePool (cached)"]
              end

              subgraph CachedNodes["Karpenter Nodes"]
                  EBSSnapshot["EBS Snapshot Volume"]
                  Containerd["containerd (pre-seeded)"]
                  Workload["whoami pods"]
              end
          end

          Builder["Builder EC2 (temporary)"]
          Snapshot["EBS Snapshot"]
      end

      NuonAPI -->|generates| Stack
      Stack -->|provisions| Runner
      Runner -->|provisions| EKS
      Runner -->|launches| Builder
      Builder -->|pulls images, creates| Snapshot
      EC2NodeClass -->|mounts| Snapshot
      NodePool -->|uses| EC2NodeClass
      NodePool -->|provisions| CachedNodes
      EBSSnapshot -->|seeds| Containerd
      Containerd -->|instant start| Workload

```

### Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

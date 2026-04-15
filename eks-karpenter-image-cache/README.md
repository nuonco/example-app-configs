<center>
<h1> EKS Karpenter Image Cache </h1>
EKS cluster with Karpenter and pre-cached container images via custom AMIs.
Large images are pulled once into a custom AMI during provisioning. Karpenter nodes launch with images already in containerd so pods start instantly without registry pulls.

Nuon Install Id: {{ .nuon.install.id }}

AWS Region: {{ .nuon.install_stack.outputs.region }}

</center>

## How It Works

1. The `image_cache` Terraform component launches a temporary EC2 instance using the EKS-optimized AL2023 AMI, pulls the specified container images into containerd, and creates a custom AMI.
2. The `node_class` component creates a Karpenter EC2NodeClass that references the custom AMI via `amiSelectorTerms`.
3. The `node_pool` component creates a Karpenter NodePool referencing the cached EC2NodeClass.
4. When pods are scheduled, Karpenter launches nodes from the custom AMI with images already present in containerd's content store.
5. Kubelet sees the images as "already present on machine" and skips registry pulls entirely.

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
                  Containerd["containerd (pre-baked)"]
                  Workload["whoami pods"]
              end
          end

          Builder["Builder EC2 (temporary)"]
          AMI["Custom AMI"]
      end

      NuonAPI -->|generates| Stack
      Stack -->|provisions| Runner
      Runner -->|provisions| EKS
      Runner -->|launches| Builder
      Builder -->|pulls images, creates| AMI
      EC2NodeClass -->|references| AMI
      NodePool -->|uses| EC2NodeClass
      NodePool -->|provisions| CachedNodes
      Containerd -->|instant start| Workload

```

### Full State

<details>
<summary>Full Install State</summary>
<pre>{{ toPrettyJson .nuon }}</pre>
</details>

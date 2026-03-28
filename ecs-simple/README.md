{{ $region := .nuon.cloud_account.aws.region }}

<center>

<h1>ECS Simple</h1>

<small>
{{ if .nuon.install_stack.outputs }} AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} |
{{ dig "region" "xx-vvvv-00" .nuon.install_stack.outputs }} |
{{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }} {{ else }} AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}
</small>

[https://whoami.{{.nuon.sandbox.outputs.nuon_dns.public_domain.name}}](https://whoami.{{.nuon.sandbox.outputs.nuon_dns.public_domain.name}})

</center>

## Components

```mermaid

  graph TD

      subgraph Nuon["Nuon Control Plane"]
          NuonAPI["Nuon API"]
      end

      subgraph Clients["Clients"]
          cURL["cURL"]
          Browser["Web browser"]
          cURL ~~~ Browser
      end

      subgraph VPC["Customer Cloud VPC (AWS)"]
          Runner["Nuon Runner"]
          ACM["ACM Certificate"]
          ALB["Application Load Balancer"]
          Stack["CloudFormation Stack"]
          ECR["ECR Repository"]

          subgraph ECS["ECS Cluster"]
              Service["ECS Service (whoami)"]
          end
      end

      NuonAPI -->|generates| Stack
      Runner -->|mirrors image to| ECR
      Stack["CloudFormation Stack"] -->|provisions| Runner
      Runner -->|provisions| ECS
      Runner -->|provisions| ACM
      Runner -->|provisions| ALB
      Runner -->|provisions| Service
      ECR -->|pulls image| Service

      ACM -->|TLS| ALB
      ALB --> Service
      Browser -->|HTTPS| ALB
      cURL -->|HTTPS| ALB

```

### Cluster

A simple ECS cluster with capacity for EC2 based services and Fargate services.

### Service

The whoami service.

## Full State

Click "Manage > State"

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
  certificate["certificate<br/>1-tf-certificate.toml"]
  whoami["whoami<br/>2-tf-service.toml"]
  cluster["cluster<br/>0-tf-cluster.toml"]
  alb["alb<br/>3-tf-alb.toml"]
  img_whoami["img_whoami<br/>0-img-whoami.toml"]

  cluster --> whoami
  img_whoami --> whoami
  alb --> whoami
  certificate --> alb

  class certificate,whoami,cluster,alb tfClass;
  class img_whoami imgClass;

  classDef tfClass fill:#D6B0FC,stroke:#8040BF,color:#000;
  classDef imgClass fill:#FCA04A,stroke:#CC803A,color:#000;
```

### Cluster

A simple ECS cluster with capacity for EC2 based services and Fargate services.

### Service

The whoami service.

## Full State

Click "Manage > State"

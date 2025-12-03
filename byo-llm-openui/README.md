{{ $region := .nuon.cloud_account.aws.region }}

<center>

<h1>BYO-LLM: Open WebUI</h1>

<small>
{{ if .nuon.install_stack.outputs }} AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} |
{{ dig "region" "xx-vvvv-00" .nuon.install_stack.outputs }} |
{{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }} {{ else }} AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}
</small>

[UI](https://ui.{{.nuon.sandbox.outputs.nuon_dns.public_domain.name}})

</center>

## Components

```mermaid
graph TD
  certificate["certificate<br/>1-tf-certificate.toml"]
  img_open_webui["img_open_webui<br/>0-img-openwebui.toml"]
  open_webui["open_webui<br/>2-tf-service.toml"]
  cluster["cluster<br/>0-tf-cluster.toml"]
  alb["alb<br/>3-tf-alb.toml"]

  alb --> open_webui
  cluster --> open_webui
  img_open_webui --> open_webui
  certificate --> alb

  class certificate,open_webui,cluster,alb tfClass;
  class img_open_webui imgClass;

  classDef tfClass fill:#D6B0FC,stroke:#8040BF,color:#000;
  classDef imgClass fill:#FCA04A,stroke:#CC803A,color:#000;
```

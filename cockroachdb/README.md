{{ $region := .nuon.cloud_account.aws.region }}

<center>

<h1>CockroachDB</h1>

<small>
{{ if .nuon.install_stack.outputs }} AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} |
{{ dig "region" "xx-vvvv-00" .nuon.install_stack.outputs }} |
{{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }} {{ else }} AWS | 000000000000 | xx-vvvv-00 | vpc-000000
{{ end }}
</small>

</center>

## Component Diagram

```mermaid
graph TD
  karpenter_nodepools["karpenter_nodepools<br/>1-karpenter-nodepools.toml"]
  crd_tailscale_operator["crd_tailscale_operator<br/>2-crd-tailscale_operator.toml"]
  storage_class["storage_class<br/>1-storage_class.toml"]
  cockroach-operator-crds["cockroach-operator-crds<br/>1-cockroach-operators.toml"]
  img_tailscale_operator["img_tailscale_operator<br/>0-image-tailscale_operator.toml"]
  tailscale_proxy["tailscale_proxy<br/>2-km-tailscale_proxy.toml"]


  class karpenter_nodepools,crd_tailscale_operator,storage_class,cockroach-operator-crds,tailscale_proxy tfClass;
  class img_tailscale_operator imgClass;

  classDef tfClass fill:#D6B0FC,stroke:#8040BF,color:#000;
  classDef imgClass fill:#FCA04A,stroke:#CC803A,color:#000;
  classDef extClass fill:#CCCCCC,stroke:#666666,color:#000,stroke-dasharray: 5 5;
```

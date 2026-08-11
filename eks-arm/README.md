# EKS ARM

Runs httpbin on EKS using an arm64 image on Graviton instances.

## URL

{{ if and .nuon.sandbox.populated .nuon.sandbox.outputs }}

| Service | URL                                                                                                                                |
| ------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| httpbin | [httpbin.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}](http://httpbin.{{ .nuon.sandbox.outputs.nuon_dns.public_domain.name }}) |

{{ else }} Results will be visible after the sandbox is deployed. {{ end }}

## The ARM bits

`sandbox.tfvars` — both settings are required and must agree. Setting the
instance type alone fails: the node group defaults to an x86 AMI, and AWS
rejects a node group whose instance architecture doesn't match its AMI
type.

```hcl
ami_type              = "AL2023_ARM_64_STANDARD"
default_instance_type = "t4g.medium"
```

## Image

`ghcr.io/mccutchen/go-httpbin:2.18.2` — multi-arch, publishes
`linux/arm64`.

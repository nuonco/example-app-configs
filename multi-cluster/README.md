<center>
<h1>EKS Multi-Cluster</h1>
Application config with two EKS Clusters with disparate workloads.
<small> AWS | {{ .nuon.install_stack.outputs.region }} </small>
</center>

An app config with two clusters. This app is intended to show how one may structure an application with multiple
clusters. For example, a cluster for `public` workloads (e.g. api services) and a cluster for `compute` workloads (e.g.
inference workloads).

1. `sandbox`'s cluster: hosts `public` workloads
2. `cluster` component: hosts `compute` workloads

Both clusters are deployed into the same VPC.

## Public Workloads

This is just a whoami service with an AWS ALB Ingress. To test, either click the url
[https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}](https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}})
or open a terminal and run the following command:

```bash
curl https://{{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
```

Expected output:

```bash
Hostname: whoami-78ffb6cbf9-w6tcc
IP: 127.0.0.1
IP: ::1
IP: 10.128.134.220
IP: fe80::a0b5:67ff:fe1f:795
RemoteAddr: 10.128.0.152:44048
GET / HTTP/1.1
Host: {{.nuon.inputs.inputs.sub_domain}}.{{.nuon.install.sandbox.outputs.nuon_dns.public_domain.name}}
User-Agent: curl/8.7.1
Accept: */*
X-Amzn-Trace-Id: Root=1-689f5793-4409b4cb4c923e0b0189cd69
X-Forwarded-For: xxx.xxx.xxx.xxx
X-Forwarded-Port: 443
X-Forwarded-Proto: https
```

## Private Workloads

We deploy `whoami` without an ingress. This is just a dummy workload.

## Targeted Actions

We use actions to inspect deployments. We can target specific clusters by setting `kubernetes_context`. See
[compute_get_deployments](./actions/compute_get_deployments.toml) for an example of an action that targets a specific
cluster.

## Components

<nuon-config-graph></nuon-config-graph>

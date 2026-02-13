{{ $region := .nuon.cloud_account.aws.region }}

<center>

<h1>BYO EKS</h1>

{{ if .nuon.install_stack.outputs }}

AWS | {{ dig "account_id" "000000000000" .nuon.install_stack.outputs }} | {{ $region }} |
{{ dig "vpc_id" "vpc-000000" .nuon.install_stack.outputs }}

{{ else }}

AWS | 000000000000 | xx-vvvv-00 | vpc-000000

{{ end }}

<small>An example application of an app deployed into an existing AWS EKS cluster.</small>

</center>

### Shifting Permissions Right

This app config uses [custom nested stacks](https://docs.nuon.co/guides/custom-nested-stacks) to shift sensitive EKS and
Kubernetes permissions out of the runner and into the customer's CloudFormation execution context. The install stack
provisions three custom nested stacks, in order:

1. **`runner_sg_eks_access`** — Grants the runner subnet's security group network access to the existing EKS cluster.
2. **`k8s_namespaces`** — Creates Kubernetes namespaces via a Lambda-backed custom resource. Namespaces are specified by
   the customer at install time via the `namespaces` input.
3. **`eks_access_entries`** — Creates namespace-scoped EKS access entries for the runner's provision, deprovision, and
   maintenance IAM roles. Access is limited to the namespaces created in the previous stack.

Because these resources are created by CloudFormation — not by the runner — the customer is the one granting EKS and
Kubernetes access, using their own IAM permissions at stack execution time. The runner roles never need
`eks:CreateAccessEntry`, `eks:AccessKubernetesApi`, or the ability to create namespaces. They receive only the
namespace-scoped access the customer explicitly provisions.

This means the runner's IAM permission boundaries (`permissions/`) can be tightly scoped to the infrastructure the
components actually manage, with no cluster-wide Kubernetes privileges.

### Inputs

| Name           | Group | Description                                                                  |
| -------------- | ----- | ---------------------------------------------------------------------------- |
| `cluster_name` | eks   | Name of the existing EKS cluster. Required.                                  |
| `namespaces`   | eks   | Comma-separated list of namespaces to create and grant the runner access to. |
| `domain`       | dns   | Root domain for Route53 / API Gateway.                                       |
| `sub_domain`   | dns   | Sub domain for the API Gateway.                                              |

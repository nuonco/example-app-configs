# Customer Cluster

An AWS EKS Auto Mode cluster modeled after the [`aws-eks-auto-sandbox`](https://github.com/nuonco/aws-eks-auto-sandbox),
intended to host customer / untrusted workloads alongside the primary sandbox cluster.

Differences from the upstream sandbox:

- No `nuon_dns` (Route 53 / external-dns / cert-manager / ingress-nginx / alb-controller) — DNS is provided by the
  primary sandbox cluster.
- No ECR — the primary sandbox already provisions a repository.
- No kyverno, metrics-server, or `additional_irsas` — out of scope for an untrusted-workload cluster.

## Runner access

The component takes the install-stack runner role ARNs (`provision_iam_role_arn`, `maintenance_iam_role_arn`,
`deprovision_iam_role_arn`, optional `break_glass_iam_role_arn`) and creates EKS access entries for each, joined to
matching Kubernetes groups (`provision`, `maintenance`, `deprovision`, `break_glass`).

A `runner_cluster_access` security-group ingress rule is also created so the runner ASG can reach the cluster API
endpoint.

## Inputs

| Variable                   | Description                                                     |
| -------------------------- | --------------------------------------------------------------- |
| `nuon_id`                  | The install ID. Used for naming and tag lookups.                |
| `region`                   | AWS region the cluster is created in.                           |
| `vpc_id`                   | VPC the cluster is provisioned in (from the install stack).     |
| `provision_iam_role_arn`   | Runner provision role — granted cluster-admin via access entry. |
| `maintenance_iam_role_arn` | Runner maintenance role — bound to the `maintenance` group.     |
| `deprovision_iam_role_arn` | Runner deprovision role — granted cluster-admin.                |
| `break_glass_iam_role_arn` | Optional break-glass role — granted cluster-admin.              |
| `cluster_name`             | Override cluster name. Defaults to the install ID.              |
| `cluster_version`          | Kubernetes version. Defaults to `1.34`.                         |
| `eks_compute_config`       | Auto Mode compute config. Defaults to `general-purpose`.        |
| `additional_namespaces`    | Extra namespaces to create on the cluster.                      |
| `ebs_storage_class`        | Toggle / configure the Auto Mode EBS StorageClass.              |

## Example configuration

```toml
name              = "cluster"
type              = "terraform_module"
terraform_version = "1.13.5"

[public_repo]
repo      = "nuonco/example-app-configs"
directory = "multi-cluster/src/components/cluster"
branch    = "main"

[vars]
nuon_id      = "{{ .nuon.install.id }}"
region       = "{{ .nuon.install_stack.outputs.region }}"
vpc_id       = "{{ .nuon.install_stack.outputs.vpc_id }}"
cluster_name = "c-{{ .nuon.install.id }}"

provision_iam_role_arn   = "{{ .nuon.install_stack.outputs.provision_iam_role_arn }}"
maintenance_iam_role_arn = "{{ .nuon.install_stack.outputs.maintenance_iam_role_arn }}"
deprovision_iam_role_arn = "{{ .nuon.install_stack.outputs.deprovision_iam_role_arn }}"
```

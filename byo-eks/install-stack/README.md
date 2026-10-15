# BYO VPC install stack

Terraform install stack for a VPC the customer already owns. It follows the
[AWS install stack](https://github.com/nuonco/install-stacks/tree/main/aws): the same runner, IAM roles, secrets, and phone-home payload. It does not create a VPC or subnets. Those IDs are inputs, the same ones the CloudFormation template in the parent directory accepts.

Subnet IDs are checked against the VPC. The runner launches with no public IP, so its subnet must have a `0.0.0.0/0` route to a NAT gateway, transit gateway, or other egress appliance. A route that only targets an internet gateway is refused.

## Maintenance access

When `eks_cluster_arn` and `maintenance_namespaces` are both set, the maintenance role gets an EKS access entry with **no** access policy. Kubernetes permissions come from a Role and RoleBinding in each listed namespace, bound to the group `nuon:install-maintenance`.

This stack does not deploy application workloads. The sample app that uses this BYO VPC template deploys only into `whoami` (the whoami Deployment and Service, and the ALB Ingress). Pass that namespace, or the namespaces your install actually uses. No other namespace receives a Role.

One cluster-scoped grant remains: read of `NetworkPolicy`. Helm lists those with an empty namespace during upgrade, and a namespaced Role cannot authorize that call. The ClusterRole is read-only. Creates and updates stay on the namespace Roles.

The identity that runs `terraform apply` needs permission to create those Roles. The maintenance role itself is not used for that write.

Leave `eks_cluster_arn` empty to skip Kubernetes RBAC. That is the same shape as the CloudFormation template, which has no cluster.

## Apply

Nuon-generated values (`nuon_install_id`, runner settings, the phone-home URL, and the IAM policy documents) arrive in the vendor tfvars. Copy `terraform.tfvars.example` to `terraform.tfvars` for the VPC, subnets, and optional cluster.

```sh
terraform init
terraform plan
terraform apply
```

Phone-home output keys match the CloudFormation payload, including comma-joined `public_subnets` and `private_subnets`.

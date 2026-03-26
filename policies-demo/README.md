# EKS Simple Auto Mode - Policies Demo

This app configuration demonstrates [Nuon Policies](https://docs.nuon.co/concepts/policies) by deploying a whoami service on AWS EKS Auto Mode alongside components and policies that intentionally trigger violations. 

This app demonstrates samples of polices you can automatically enforce on a production BYOC deployment with Nuon.

First time creating an app? Check out our [getting started guide](https://docs.nuon.co/get-started/quickstart)

## Setup

```bash
nuon apps create --name policies-demo
nuon apps sync
```

## Testing Policy Violations

This example app has [components](policies-demo/tree/main/components) S3 bucket, DynamoDB, and whomai-kube-system that already intentionally violate the example [policies](policies-demo/tree/main/policies). 

Scenario 1, 2 and 3 trigger automatically on your first [install](https://docs.nuon.co/guides/app-install-life-cycle#install-life-cycle).


## Policy Scenario Detail

| # | Policy | Type | Enforcement | Trigger | Expected Result |
|---|--------|------|-------------|---------|-----------------|
| 1 | Public EKS Endpoint | `sandbox` / OPA | **warn** | `cluster_endpoint_public_access = true` in sandbox | Warning in UI — continue anyway |
| 2 | S3 Bucket Creation | `terraform_module` / OPA | **deny** | `s3_bucket` component creates an S3 bucket | Deploy blocked |
| 3 | Database Modification | `terraform_module` / OPA | **deny** | Change `billing_mode` input after first deploy | First deploy passes, redeploy blocked |
| 4 | Restricted Namespaces | `helm_chart` / OPA | **deny** | `whoami_kube_system` deploys to `kube-system` | Deploy blocked |
| 5a | Runner-Only Access | `sandbox` / OPA | **deny** | Non-runner IAM principals in EKS access entries | Deploy blocked (latent) |
| 5b | ECR Images Only | `helm_chart` / OPA | **deny** | `traefik/whoami:latest` is not from ECR | Deploy blocked |

### Scenario 1: Public EKS Endpoint (Warning)

The sandbox provisions an EKS cluster with `cluster_endpoint_public_access = true`. During sandbox provisioning, the policy evaluates the Terraform plan and produces a **warning**.

### Scenario 2: S3 Bucket Creation (Deny)

Deploy the install. When the `s3_bucket` component runs, the policy evaluates its Terraform plan and **denies** the `aws_s3_bucket` resource creation. The deploy is blocked and the denial message appears in the Policy Evaluation card.

### Scenario 3: Restricted Namespaces (Deny)

The `whoami_kube_system` component attempts to deploy a manifest to the `kube-system` namespace. The policy evaluates the rendered manifest and **denies** deployment to any restricted namespace (`default`, `kube-system`, `kube-public`).

### Scenario 4: Database Modification (Deny After First Deploy)

1. Deploy with the default `billing_mode = PAY_PER_REQUEST` — the `demo_database` component deploys successfully since the policy only blocks `update` and `delete` actions.
2. Change the `billing_mode` input to `PROVISIONED` in the Nuon dashboard.
3. Redeploy — the policy detects the `update` action on the DynamoDB table and **denies** the deploy with: *"Database modification denied: changes could cause downtime"*.

### Scenario 5a: Runner-Only Access Entries (Deny)

This policy is **latent** by default — the current sandbox configuration only creates access entries for the runner roles (provision, maintenance, deprovision), which are allowed. To trigger the denial:

1. Add a non-runner access entry to `sandbox.tfvars` (e.g., an additional IAM user or role).
2. Re-provision the sandbox — the policy will **deny** the extra access entry.

### Scenario 5b: ECR Images Only (Deny)

The `whoami` component uses `traefik/whoami:latest` which is a public Docker Hub image, not from the install's ECR repository. The policy evaluates the rendered Kubernetes manifests and **denies** any container image that does not contain `.dkr.ecr.` in its image reference.

## Components

| Component | Type | Purpose |
|-----------|------|---------|
| `certificate` | terraform_module | ACM wildcard certificate |
| `whoami` | kubernetes_manifest | Whoami deployment in `whoami` namespace |
| `application_load_balancer` | helm_chart | ALB ingress for whoami |
| `s3_bucket` | terraform_module | S3 bucket (denied by policy #2) |
| `demo_database` | terraform_module | DynamoDB table (denied on update by policy #4) |
| `whoami_kube_system` | kubernetes_manifest | Whoami in `kube-system` (denied by policy #3) |

## Viewing Policy Results in Nuon

1. Navigate to the install in the Nuon Dashboard.
2. Click the Workflow tab.
3. Click on any workflow step to see the **Policy Evaluation** card.
4. Passed policies show green checkmarks, denied policies show red indicators with violation messages, and warnings show orange indicators.

## Application URLs

Access your deployed whoami web app here:

- **Whoami**: https://{{ .nuon.inputs.inputs.subdomain }}.{{ .nuon.install.sandbox.outputs.nuon_dns.public_domain.name }}

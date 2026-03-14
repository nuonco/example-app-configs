### What this app does?

A simple example of provisioning an AWS ECS cluster with a `whoami` HTTP server, demonstrating granular IAM permissions, break-glass emergency access, and optional vendor cross-account role delegation for observability and debugging.

### Prerequisites

- AWS account connected to Nuon (handled during onboarding

### How to install/What to expect next?

- Clicking install will generate a link for you to log into AWS and create a CloudFormation stack which creates the VPC, EC2 VM, and a runner, an agent that receives jobs to deploy whoami in your VPC
- If configured, you may be prompted to approve plan steps
- Average installation time is 20 minutes due to creating the VPC, ASG, VM,  AWS EKS cluster other app components.

### What gets deployed in your cloud account?

- Dedicated VPC
- AWS ECS cluster
- whoami app
- A whoami container image
- AWS certificate
- Application load balancer
- Granular IAM operational roles (provision, maintenance, break-glass, deprovision)
- Optional cross-account vendor read-only role (if vendor_role_arn is provided)

```mermaid

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
          BreakGlass["Break-Glass IAM Role"]
          VendorRole["Vendor Delegated Role (optional)"]

          subgraph ECS["ECS Cluster"]
              Service["ECS Service (whoami)"]
          end
      end

      NuonAPI -->|generates| Stack
      Runner -->|mirrors image to| ECR
      Stack -->|provisions| Runner
      Runner -->|provisions| ECS
      Runner -->|provisions| ACM
      Runner -->|provisions| ALB
      Runner -->|provisions| Service
      Runner -->|provisions| BreakGlass
      Runner -->|provisions| VendorRole
      ECR -->|pulls image| Service

      ACM -->|TLS| ALB
      ALB --> Service
      Browser -->|HTTPS| ALB
      cURL -->|HTTPS| ALB

```

### What inputs can you enter?

- AWS region
- Public domain
- Subdomain
- Vendor role ARN (optional — enables read-only cross-account access for vendor observability) 

### Security & compliance

- [Nuon BYOC trust center](https://docs.nuon.co/guides/vendor-customers)
- All resource provisioning and scripts are performed by an agent in a VM in your VPC — no cross-account access granted
- Maintenance role uses tag-scoped, least-privilege IAM policies with explicit Secrets Manager deny
- Break-glass role provides emergency elevated access bounded by permission boundary to prevent cross-install actions
- IMDSv2 enforced on all EC2 instances
- Optional vendor role is read-only (ECS + CloudWatch logs) and scoped to this install only

### Nuon concepts

The following terminology is core to the Nuon BYOC platform.

#### Connect Your App | App Config
- App (collection of TOML config files that provision and manage the whoami app in your cloud account)
- Sandbox (the underlying infrastructure, in this case an ECS cluster)
- Component (the Terraform to deploy whoami ECS service, container image, AWS TLS certificate, ALB, and IAM roles)
- Inputs (dynamic values specific to the install e.g., public domain, subdomain, vendor role ARN)
- Secrets (sensitive values either auto-created or entered by the customer during Stack creation - stored in AWS Secrets Manager)

#### Support Customer Infrastructure | Customer Config

- Installs (Installs are instances of an application in your (the customer) cloud account.)
- Stack (the AWS CloudFormation stack that provisions the VPC, subnets, IAM roles, ASG, EC2 VM and Runner (agent) Docker service)
- Runners (Egress-only agents deployed in customer cloud accounts that execute all provisioning, deployment, and day-2 operations.)
- Operational Roles (IAM roles to perform different operations for least-privilege access across sandbox, components, and actions.)

#### Continuous Delivery | Day-2 Operations

- Workflows (Orchestration of the deployment, update & teardown lifecycle of apps, components, and actions)
- Actions (Bash scripts for health checks, migrations, debugging, and day-2 operations)
- Policies (Rego & Kyverno configs to enforce compliance and security rules at infrastructure plan steps)
- Customer Portal (A customer-facing web dashboard to initiate and monitor an app's install in a customer's VPC)

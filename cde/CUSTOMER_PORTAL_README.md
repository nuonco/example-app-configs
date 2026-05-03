### What this app does?

A cloud development environment running in your AWS account — a single EC2 VM with SSH access, an optional browser-based VS Code IDE, Docker, and Claude Code CLI.

### Prerequisites

- A valid AWS account
- An SSH key pair (you will paste the public key during setup)

### How to install / What to expect next?

- Clicking install generates a CloudFormation link to deploy the stack in your AWS account
- The stack provisions a VPC, EC2 instance, Elastic IP, DNS record, and an optional HTTPS-fronted IDE
- After provisioning, a setup action runs automatically to install any optional tools you selected
- SSH access is available immediately at the DNS hostname shown in the portal
- Average installation time is 10–15 minutes

### What gets deployed in your cloud account?

- VPC with public subnets
- EC2 instance (instance type of your choice) with an Elastic IP and Route53 A record (`dev.<install-id>.nuon.run`)
- IAM instance profile with SSM access (used by the runner to configure the VM)
- Optional: ALB + ACM certificate + Route53 alias for VS Code Web at `ide.<install-id>.nuon.run`
- Optional: Docker, VS Code Web (code-server), Claude Code CLI

### What inputs can you enter?

- SSH public key (required — paste the output of `cat ~/.ssh/id_rsa.pub`)
- Operating system (Ubuntu 24.04 LTS or Amazon Linux 2023)
- Instance type (t3a.medium through m7i.xlarge)
- Optional tools: Docker, VS Code Web, Claude Code
- Anthropic API key (only required if Claude Code is enabled)

### Day-2 operations

- **Start / Stop** the VM via the portal to pause billing when not in use
- **Install Claude Code** action updates the CLI to the latest version independently
- **Healthcheck** action verifies SSH port reachability

### Security & compliance

- [Nuon BYOC trust center](https://docs.nuon.co/guides/vendor-customers)
- All provisioning runs inside your VPC — no cross-account access is granted to the vendor
- SSH authentication is key-only; password authentication is disabled
- The runner uses SSM (not an open inbound port) to execute setup scripts on the VM

### Nuon concepts

#### Connect Your App | App Config
- App (TOML configs that provision and manage the dev environment in your cloud account)
- Sandbox (VPC, subnets, Elastic IP, DNS zone)
- Component (Terraform module that creates the EC2 instance and optional ALB/ACM resources)
- Inputs (customer-provided values: SSH key, instance type, OS, optional tools)

#### Support Customer Infrastructure | Customer Config
- Installs (instances of the app running in your cloud account)
- Stack (CloudFormation stack that provisions the VPC, runner, and IAM roles)
- Runners (egress-only agents in your VPC that execute all provisioning and day-2 operations)

#### Continuous Delivery | Day-2 Operations
- Actions (start/stop VM, install tools, healthcheck)
- Workflows (orchestrate the full install, update, and teardown lifecycle)

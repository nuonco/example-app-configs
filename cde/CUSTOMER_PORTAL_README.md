### What this app does?

A cloud development environment running in your AWS account — a single EC2 VM with SSH access, an optional browser-based VS Code IDE, Docker, and Claude Code CLI.

### Prerequisites

- A valid AWS account
- An SSH key pair (your vendor will need your public key to configure access)
- An Anthropic API key if Claude Code is enabled (get one at [console.anthropic.com](https://console.anthropic.com))

### How to install / What to expect next?

- Clicking install generates a CloudFormation link to deploy the stack in your AWS account
- The stack provisions a VPC, EC2 instance, Elastic IP, DNS record, and an optional HTTPS-fronted IDE
- After provisioning, a setup action runs automatically to install any optional tools you selected
- SSH access is available immediately at the DNS hostname shown in the customer portal
- Average installation time is 10–15 minutes

### What gets deployed in your cloud account?

- VPC with public subnets
- EC2 instance (instance type of your choice) with an Elastic IP and Route53 A record (`dev.<install-id>.nuon.run`)
- IAM instance profile with SSM access (used by the runner to configure the VM)
- Optional: ALB + ACM certificate + Route53 alias for VS Code Web at `ide.<install-id>.nuon.run`
- Optional: Docker, VS Code Web (code-server), Claude Code CLI

### What inputs can you enter?

**Vendor-configured** (pre-set by your vendor before deployment):
- SSH public key
- Operating system (Ubuntu 24.04 LTS or Amazon Linux 2023)
- Instance type (t3a.medium through m7i.xlarge)
- Optional tools: Docker, VS Code Web, Claude Code
- Git user name and email
- Dotfiles repo URL

**Customer-configured** (you enter this):
- Anthropic API key (required if Claude Code is enabled)

### Day-2 operations

- **Start / Stop** the VM via the vendor dashboard to pause billing when not in use
- **Add SSH Key** action appends an additional public key to `authorized_keys`
- **Install Dotfiles** action re-clones and re-runs your dotfiles repo (useful after updates)
- **Install Claude Code** action installs or updates the CLI to the latest version
- **Healthcheck** action verifies instance state and SSH port reachability

### Security & compliance

- [Nuon BYOC trust center](https://docs.nuon.co/guides/vendor-customers)
- All provisioning runs inside your VPC — no cross-account access is granted to the vendor
- SSH authentication is key-only; password authentication is disabled
- The runner uses SSM (not an open inbound port) to execute setup scripts on the VM
- Your Anthropic API key is stored as an AWS SSM SecureString encrypted at rest with KMS in your own account — the vendor never sees it, and the VM is granted least-privilege access to read only its own parameter path

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

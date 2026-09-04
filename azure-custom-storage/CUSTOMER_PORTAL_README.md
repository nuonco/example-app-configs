### What this app does?

A simple example of provisioning an Azure storage account with the install stack, then reading it back from a Terraform component.

### Prerequisites

- Azure subscription connected to Nuon (handled during onboarding)

### How to install/What to expect next?

- Clicking install will generate a link for you to deploy a Bicep template in Azure which creates the VNet, VM, runner, and a storage account
- If configured, you may be prompted to approve plan steps
- Average installation time is 20 minutes due to creating the VNet, VM, and storage account

### What gets deployed in your cloud account?

- Dedicated VNet
- Nuon runner VM
- Azure storage account (created with the install stack)
- A marker blob written by the pass-through component

### What inputs can you enter?

- Azure region
- Blob versioning

### Security & compliance

- [Nuon BYOC trust center](https://docs.nuon.co/guides/vendor-customers)
- All resource provisioning and scripts are performed by an agent in a VM in your VNet - no cross-account access granted to the vendor

### Nuon concepts

The following terminology is core to the Nuon BYOC platform.

#### Connect Your App | App Config
- App (collection of TOML config files that provision and manage storage in your cloud account)
- Sandbox (the underlying infrastructure around the runner)
- Component (Terraform that reads the storage account created by the install stack)
- Inputs (dynamic values specific to the install, e.g. blob versioning)

#### Support Customer Infrastructure | Customer Config

- Installs (instances of an application in your cloud account)
- Stack (the Azure Bicep deployment that provisions the VNet, VM, runner, and custom storage account)
- Runners (egress-only agents deployed in customer cloud accounts that execute provisioning, deployment, and day-2 operations)
- Operational Roles (Azure RBAC roles for least-privilege access across sandbox, components, and actions)

#### Continuous Delivery | Day-2 Operations

- Workflows (orchestration of the deployment, update, and teardown lifecycle)
- Actions (scripts for health checks, debugging, and day-2 operations)
- Policies (configs to enforce compliance and security rules at infrastructure plan steps)
- Customer Portal (a customer-facing web dashboard to initiate and monitor an app's install)

# Dynamic Roles Kitchen Sink Example

A comprehensive demonstration of Nuon's dynamic operation roles feature, showcasing best practices for operation-specific IAM permission management.

## Purpose

This example app demonstrates:

- **Operation-Specific Roles**: Different IAM roles for deploy vs teardown operations
- **Component Isolation**: Lambda permissions separate from CloudFront permissions
- **Least Privilege**: Minimal IAM permissions with no wildcards or admin access
- **Permission Boundaries**: Double protection through role policies + boundaries
- **Action-Based Roles**: Read-only roles for diagnostic actions
- **Sandbox Operation Roles**: Provision, reprovision, and deprovision with scoped permissions

**This is a reference implementation, not a production-ready application.**

## Architecture

```
┌─────────────────┐
│  Docker Build   │ (maintenance role)
│  docker_image   │
└────────┬────────┘
         │ Produces: image.repository, image.tag
         ▼
┌─────────────────┐
│ Lambda Function │ Deploy: lambda-deploy-role
│ lambda_function │ Teardown: lambda-teardown-role
└────────┬────────┘
         │ Provides: lambda_function_url, function_name
         ▼
┌─────────────────┐
│   CloudFront    │ Deploy: cloudfront-deploy-role
│   Distribution  │ Teardown: cloudfront-teardown-role
└─────────────────┘

Actions (action-diagnostics-role):
  - health_check
  - view_config
  - diagnostics
```

## Components

### 1. Docker Image (`docker_image`)
- **Type**: Docker build
- **Role**: `maintenance`
- **Purpose**: Build Lambda container image from Node.js application
- **Outputs**: `image.repository`, `image.tag`

### 2. Lambda Function (`lambda_function`)
- **Type**: Terraform module
- **Deploy Role**: `lambda-deploy-role` (creation/update permissions)
- **Teardown Role**: `lambda-teardown-role` (deletion-only permissions)
- **Resources**:
  - Lambda function with container image
  - Lambda function URL (public access)
  - IAM execution role
  - CloudWatch log group
- **Outputs**: `lambda_function_url`, `function_name`, `function_arn`

### 3. CloudFront Distribution (`cloudfront_distribution`)
- **Type**: Terraform module
- **Deploy Role**: `cloudfront-deploy-role` (creation/update permissions)
- **Teardown Role**: `cloudfront-teardown-role` (deletion-only permissions)
- **Resources**:
  - CloudFront distribution with Lambda origin
  - Cache behavior configuration
- **Outputs**: `distribution_id`, `distribution_domain_name`

## Operation Roles Matrix

| Principal | Operation | Role | IAM Permissions |
|-----------|-----------|------|-----------------|
| `component:docker_image` | deploy | maintenance | ECR push, logs read |
| `component:lambda_function` | deploy | **lambda-deploy-role** | Lambda create/update, IAM PassRole (scoped), ECR pull, logs create |
| `component:lambda_function` | teardown | **lambda-teardown-role** | Lambda delete, logs delete (NO creation) |
| `component:cloudfront_distribution` | deploy | **cloudfront-deploy-role** | CloudFront create/update, Lambda read (NO deletion) |
| `component:cloudfront_distribution` | teardown | **cloudfront-teardown-role** | CloudFront delete (NO creation) |
| `sandbox` | provision | provision | Route53, IAM, ECR, VPC, compute creation |
| `sandbox` | reprovision | **sandbox-infra-role** | Infrastructure updates (NO create/delete) |
| `sandbox` | deprovision | deprovision | Full infrastructure deletion |
| `action:health_check` | run | maintenance | Lambda read, logs read |
| `action:view_config` | run | **action-diagnostics-role** | Lambda/CloudFront read-only |
| `action:diagnostics` | run | **action-diagnostics-role** | Full read-only diagnostic access |

## Permission Best Practices Demonstrated

### 1. No Wildcards in Actions
❌ Bad: `"Action": "lambda:*"`
✅ Good: `"Action": ["lambda:CreateFunction", "lambda:UpdateFunctionCode"]`

All IAM actions are explicitly listed.

### 2. No Admin Access
❌ Bad: `"arn:aws:iam::aws:policy/AdministratorAccess"`
✅ Good: Custom policies with specific actions

Zero usage of `AdministratorAccess` managed policy.

### 3. Resource Scoping
```json
{
  "Resource": "arn:aws:lambda:*:*:function/*{{.nuon.install.id}}*",
  "Condition": {
    "StringEquals": {
      "aws:ResourceTag/install.nuon.co/id": "{{.nuon.install.id}}"
    }
  }
}
```

Resources include install ID where possible, with tag-based conditions.

### 4. Service-Specific PassRole
```json
{
  "Action": ["iam:PassRole"],
  "Resource": "arn:aws:iam::*:role/*{{.nuon.install.id}}*",
  "Condition": {
    "StringEquals": {
      "iam:PassedToService": "lambda.amazonaws.com"
    }
  }
}
```

IAM PassRole is scoped to specific AWS services.

### 5. Permission Boundaries
Every custom role has a permission boundary that:
- Allows only operations needed for that role type
- Explicitly denies operations that should never be allowed
- Provides defense-in-depth protection

### 6. Operation Separation
- **Deploy roles**: Creation and update permissions only
- **Teardown roles**: Deletion permissions only
- **Action roles**: Read-only permissions only
- **Sandbox roles**: Phase-specific permissions (provision/update/deprovision)

### 7. Modular Policies
Large roles use multiple `[[policies]]` blocks organized by service:
- Route53 policies
- IAM policies
- VPC/networking policies
- Compute policies
- ECR policies

This improves readability and maintainability.

## Actions

### health_check
- **Role**: `maintenance`
- **Purpose**: Verify Lambda function is operational
- **Permissions**: Lambda read, function URL read
- **Usage**: Basic health verification

### view_config
- **Role**: `action-diagnostics-role`
- **Purpose**: View Lambda and CloudFront configuration
- **Permissions**: Read-only access to configuration
- **Usage**: Inspect current resource settings

### diagnostics
- **Role**: `action-diagnostics-role`
- **Purpose**: Comprehensive diagnostic information
- **Permissions**: Read-only access to Lambda, CloudFront, logs, IAM identity
- **Usage**: Troubleshooting and investigation

## Installation

### Prerequisites
- Nuon CLI installed and configured
- AWS account with appropriate permissions
- Docker (for local testing)

### Deploy the App

1. **Sync the app configuration:**
```bash
nuon apps sync --path example-app-configs/dynamic-roles-kitchen-sink
```

2. **Create an install:**
```bash
nuon installs create --app <app-id> --name test-dynamic-roles
```

3. **Deploy components:**
```bash
nuon installs deploy --install <install-id>
```

4. **Verify deployment:**
```bash
# Check Lambda function
nuon actions run --install <install-id> --action health_check

# View configuration
nuon actions run --install <install-id> --action view_config

# Full diagnostics
nuon actions run --install <install-id> --action diagnostics
```

5. **Test the Lambda function:**
```bash
# Get the CloudFront URL from outputs
curl https://<distribution-domain-name>
```

Expected response:
```json
{
  "message": "Hello from dynamic-roles-kitchen-sink!",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "installId": "ins...",
  "demonstration": {
    "purpose": "IAM operation role demonstration",
    "deployRole": "lambda-deploy-role (minimal creation permissions)",
    "teardownRole": "lambda-teardown-role (deletion-only permissions)",
    "actionRole": "action-diagnostics-role (read-only inspection)"
  }
}
```

### Teardown

```bash
nuon installs destroy --install <install-id>
```

**Note**: Teardown uses different roles than deploy:
- Lambda teardown: `lambda-teardown-role` (deletion-only)
- CloudFront teardown: `cloudfront-teardown-role` (deletion-only)

## Verifying Role Usage

### Check Which Role Was Used

In the Nuon dashboard or CLI logs, you can verify:

1. **Deploy operations** used creation-scoped roles
2. **Teardown operations** used deletion-scoped roles
3. **Actions** used read-only diagnostic roles

### Verify Permission Boundaries

Check that each role has its permission boundary applied:

```bash
aws iam get-role --role-name <install-id>-lambda-deploy-role \
  --query 'Role.PermissionsBoundary.PermissionsBoundaryArn'
```

### Test Permission Restrictions

Try operations that should fail:

```bash
# Lambda deploy role should NOT be able to delete functions
# Lambda teardown role should NOT be able to create functions
# Action diagnostics role should NOT be able to modify anything
```

## File Structure

```
dynamic-roles-kitchen-sink/
├── metadata.toml                      # App metadata
├── .meta.yaml                         # Tags and links
├── inputs.toml                        # User inputs
├── sandbox.toml                       # Sandbox configuration
├── runner.toml                        # Runner configuration
├── operation_roles.toml               # Role assignment rules (11 rules)
├── README.md                          # This file
│
├── permissions/                       # Role definitions (18 files)
│   ├── lambda_deploy_role.toml
│   ├── lambda_deploy_role_boundary.json
│   ├── lambda_teardown_role.toml
│   ├── lambda_teardown_role_boundary.json
│   ├── cloudfront_deploy_role.toml
│   ├── cloudfront_deploy_role_boundary.json
│   ├── cloudfront_teardown_role.toml
│   ├── cloudfront_teardown_role_boundary.json
│   ├── action_diagnostics_role.toml
│   ├── action_diagnostics_role_boundary.json
│   ├── sandbox_infra_role.toml
│   ├── sandbox_infra_role_boundary.json
│   ├── maintenance.toml
│   ├── maintenance_boundary.json
│   ├── provision.toml
│   ├── provision_boundary.json
│   ├── deprovision.toml
│   └── deprovision_boundary.json
│
├── components/                        # Component definitions (3 files)
│   ├── 0-docker-image.toml
│   ├── 1-lambda-function.toml
│   └── 2-cloudfront-distribution.toml
│
├── actions/                           # Action definitions (3 files)
│   ├── 0-health-check.toml
│   ├── 1-view-config.toml
│   └── 2-diagnostics.toml
│
└── src/                               # Source code
    ├── components/
    │   ├── lambda-function/           # Lambda Terraform module (4 files)
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── versions.tf
    │   └── cloudfront-distribution/   # CloudFront Terraform module (4 files)
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       └── versions.tf
    └── lambda-app/                    # Lambda application (3 files)
        ├── Dockerfile
        ├── index.js
        └── package.json
```

**Total: 39 files**

## Key Learnings

### 1. Operation-Specific Permissions Improve Security
By separating deploy and teardown permissions:
- Accidental deletions are prevented
- Audit trails are clearer
- Principle of least privilege is enforced

### 2. Component Isolation Reduces Blast Radius
Lambda roles can't affect CloudFront resources and vice versa.

### 3. Permission Boundaries Provide Defense in Depth
Even if a role policy is misconfigured, the boundary prevents privilege escalation.

### 4. Explicit Actions Beat Wildcards
`lambda:CreateFunction` is clearer than `lambda:*` and prevents accidental over-permissioning.

### 5. Tag-Based Conditions Enable Multi-Tenancy
Resources tagged with `install.nuon.co/id` can only be accessed by the correct install's roles.

### 6. Read-Only Roles Enable Safe Diagnostics
Actions with diagnostic-only roles can inspect state without risk of modification.

## Troubleshooting

### Role Not Found
If a role is not found during deployment:
- Verify `operation_roles.toml` has the correct principal and operation
- Check that the role file exists in `permissions/`
- Ensure role name matches exactly (case-sensitive)

### Permission Denied
If operations fail with permission errors:
- Check the role's IAM policy for required actions
- Verify permission boundary allows the action
- Confirm resource ARNs include install ID where required

### Terraform Validation Errors
```bash
cd src/components/lambda-function
terraform init
terraform validate
```

Check for syntax errors in `.tf` files.

### Lambda Function Not Responding
```bash
# Check logs
nuon actions run --install <install-id> --action diagnostics

# Verify function URL
aws lambda get-function-url-config \
  --function-name <install-id>-kitchen-sink
```

## Related Documentation

- [Nuon Dynamic Roles Documentation](https://docs.nuon.co/features/dynamic-roles)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Lambda Permissions](https://docs.aws.amazon.com/lambda/latest/dg/lambda-permissions.html)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)

## License

MIT

## Contributing

This is a reference example. For improvements or suggestions, please open an issue in the [nuonco/example-app-configs](https://github.com/nuonco/example-app-configs) repository.

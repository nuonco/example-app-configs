# Role Delegation

This module enables **cross-account access** from a vendor's AWS account to resources created for a customer's install.

## How It Works

1. **Vendor** authors this configuration as part of their Nuon app
2. **Customer** deploys the app to their AWS infrastructure via Nuon
3. **Customer** provides their vendor's IAM role ARN via the `vendor_role_arn` input, explicitly consenting to grant
   that role access to specific install resources
4. This module creates a **delegated role** in the customer's account with:
   - A **trust policy** allowing the vendor's role to assume it
   - **Policies** granting read-only access to the install's ECS cluster and CloudWatch logs

## Security Model

By providing a `vendor_role_arn`, the customer explicitly grants the vendor cross-account access to:

- **ECS Cluster**: Describe and list clusters, services, tasks, and container instances
- **CloudWatch Logs**: Read log streams and events for the install's log group

The vendor must call `sts:AssumeRole` on the delegated role ARN (output as `delegated_role_arn`) to obtain temporary
credentials scoped to these resources.

An optional `external_id` can be configured for additional security.

## Inputs

| Name                       | Description                                                | Required |
| -------------------------- | ---------------------------------------------------------- | -------- |
| `vendor_role_arn`          | ARN of the vendor's IAM role to grant cross-account access | Yes      |
| `cluster_arn`              | ARN of the ECS cluster                                     | Yes      |
| `cloudwatch_log_group_arn` | ARN of the CloudWatch log group                            | Yes      |
| `external_id`              | External ID for the trust relationship                     | No       |

## Outputs

| Name                  | Description                              |
| --------------------- | ---------------------------------------- |
| `delegated_role_arn`  | ARN of the role the vendor should assume |
| `delegated_role_name` | Name of the delegated role               |
| `granted_permissions` | Summary of permissions granted           |

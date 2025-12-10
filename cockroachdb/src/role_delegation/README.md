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

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.13.5 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | = 6.21.0  |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 6.21.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                          | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_eks_access_entry.delegated](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/eks_access_entry)                                | resource    |
| [aws_eks_access_policy_association.delegated_edit](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/eks_access_policy_association) | resource    |
| [aws_iam_policy.cloudwatch_logs_access](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_policy)                               | resource    |
| [aws_iam_policy.eks_cluster_access](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_policy)                                   | resource    |
| [aws_iam_role.delegated](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_role)                                                | resource    |
| [aws_iam_role_policy_attachment.eks_access](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_role_policy_attachment)           | resource    |
| [aws_iam_role_policy_attachment.logs_access](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_role_policy_attachment)          | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/caller_identity)                                 | data source |

## Inputs

| Name                                                                              | Description                                                                                     | Type          | Default | Required |
| --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ------------- | ------- | :------: |
| <a name="input_eks_cluster_arn"></a> [eks_cluster_arn](#input_eks_cluster_arn)    | ARN of the EKS cluster                                                                          | `string`      | n/a     |   yes    |
| <a name="input_eks_cluster_name"></a> [eks_cluster_name](#input_eks_cluster_name) | Name of the EKS cluster                                                                         | `string`      | n/a     |   yes    |
| <a name="input_nuon_id"></a> [nuon_id](#input_nuon_id)                            | Nuon Install ID                                                                                 | `string`      | n/a     |   yes    |
| <a name="input_region"></a> [region](#input_region)                               | AWS Region                                                                                      | `string`      | n/a     |   yes    |
| <a name="input_tags"></a> [tags](#input_tags)                                     | Tags to apply to all resources                                                                  | `map(string)` | `{}`    |    no    |
| <a name="input_vendor_role_arn"></a> [vendor_role_arn](#input_vendor_role_arn)    | ARN of the vendor's IAM role to grant cross-account access. If empty, no resources are created. | `string`      | `""`    |    no    |

## Outputs

| Name                                                                                               | Description                                                     |
| -------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| <a name="output_delegated_role_arn"></a> [delegated_role_arn](#output_delegated_role_arn)          | ARN of the delegated IAM role created in the customer's account |
| <a name="output_delegated_role_name"></a> [delegated_role_name](#output_delegated_role_name)       | Name of the delegated IAM role                                  |
| <a name="output_eks_access_entry_arn"></a> [eks_access_entry_arn](#output_eks_access_entry_arn)    | ARN of the EKS access entry for the delegated role              |
| <a name="output_eks_access_policy_arn"></a> [eks_access_policy_arn](#output_eks_access_policy_arn) | ARN of the EKS cluster access policy                            |
| <a name="output_eks_log_group_arn"></a> [eks_log_group_arn](#output_eks_log_group_arn)             | ARN of the EKS cluster CloudWatch log group                     |
| <a name="output_enabled"></a> [enabled](#output_enabled)                                           | Whether role delegation is enabled                              |
| <a name="output_granted_permissions"></a> [granted_permissions](#output_granted_permissions)       | Summary of permissions granted to the delegated role            |
| <a name="output_logs_policy_arn"></a> [logs_policy_arn](#output_logs_policy_arn)                   | ARN of the CloudWatch logs access policy                        |

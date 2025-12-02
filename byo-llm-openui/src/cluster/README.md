# ECS Cluster

Terraform module that creates an ECS cluster with mixed capacity providers for different workload types.

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

| Name                                                                 | Source                        | Version |
| -------------------------------------------------------------------- | ----------------------------- | ------- |
| <a name="module_ecs_cluster"></a> [ecs_cluster](#module_ecs_cluster) | terraform-aws-modules/ecs/aws | 6.9.0   |

## Resources

| Name                                                                                                                                                  | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_autoscaling_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/autoscaling_group)                            | resource    |
| [aws_iam_instance_profile.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_instance_profile)             | resource    |
| [aws_iam_role.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_role)                                     | resource    |
| [aws_iam_role_policy_attachment.ecs_instance](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/iam_role_policy_attachment) | resource    |
| [aws_launch_template.ecs](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/launch_template)                                | resource    |
| [aws_security_group.ecs_instances](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/security_group)                        | resource    |
| [aws_security_group_rule.ecs_from_alb](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/resources/security_group_rule)               | resource    |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/availability_zones)                 | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/caller_identity)                         | data source |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/security_group)                           | data source |
| [aws_security_groups.runner](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/security_groups)                          | data source |
| [aws_ssm_parameter.ecs_optimized_ami](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/ssm_parameter)                   | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/subnet)                                           | data source |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/subnet)                                            | data source |
| [aws_subnet.runner](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/subnet)                                            | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/subnets)                                         | data source |
| [aws_subnets.public](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/subnets)                                          | data source |
| [aws_subnets.runner](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/subnets)                                          | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/6.21.0/docs/data-sources/vpc)                                                     | data source |

## Inputs

| Name                                                                                             | Description                                                | Type          | Default       | Required |
| ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------- | ------------- | ------------- | :------: |
| <a name="input_alb_security_group_id"></a> [alb_security_group_id](#input_alb_security_group_id) | Security group ID of the ALB (optional, for ingress rules) | `string`      | `null`        |    no    |
| <a name="input_ecs_desired_capacity"></a> [ecs_desired_capacity](#input_ecs_desired_capacity)    | Desired number of EC2 instances in the ECS cluster         | `number`      | `2`           |    no    |
| <a name="input_ecs_instance_type"></a> [ecs_instance_type](#input_ecs_instance_type)             | EC2 instance type for ECS container instances              | `string`      | `"t3.medium"` |    no    |
| <a name="input_ecs_max_size"></a> [ecs_max_size](#input_ecs_max_size)                            | Maximum number of EC2 instances in the ECS cluster         | `number`      | `4`           |    no    |
| <a name="input_ecs_min_size"></a> [ecs_min_size](#input_ecs_min_size)                            | Minimum number of EC2 instances in the ECS cluster         | `number`      | `1`           |    no    |
| <a name="input_nuon_id"></a> [nuon_id](#input_nuon_id)                                           | Nuon Install ID                                            | `string`      | n/a           |   yes    |
| <a name="input_region"></a> [region](#input_region)                                              | AWS Region                                                 | `string`      | n/a           |   yes    |
| <a name="input_tags"></a> [tags](#input_tags)                                                    | Tags to apply to all resources                             | `map(string)` | `{}`          |    no    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                              | VPC ID where ECS cluster will be deployed                  | `string`      | n/a           |   yes    |

## Outputs

| Name                                                                                                                          | Description                                           |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| <a name="output_autoscaling_group_arn"></a> [autoscaling_group_arn](#output_autoscaling_group_arn)                            | ARN of the Auto Scaling Group for EC2 instances       |
| <a name="output_autoscaling_group_name"></a> [autoscaling_group_name](#output_autoscaling_group_name)                         | Name of the Auto Scaling Group for EC2 instances      |
| <a name="output_capacity_providers"></a> [capacity_providers](#output_capacity_providers)                                     | List of capacity providers configured for the cluster |
| <a name="output_cluster_arn"></a> [cluster_arn](#output_cluster_arn)                                                          | ECS cluster ARN                                       |
| <a name="output_cluster_id"></a> [cluster_id](#output_cluster_id)                                                             | ECS cluster ID                                        |
| <a name="output_cluster_name"></a> [cluster_name](#output_cluster_name)                                                       | ECS cluster name                                      |
| <a name="output_ecs_instance_role_arn"></a> [ecs_instance_role_arn](#output_ecs_instance_role_arn)                            | IAM role ARN for ECS EC2 instances                    |
| <a name="output_ecs_instance_role_name"></a> [ecs_instance_role_name](#output_ecs_instance_role_name)                         | IAM role name for ECS EC2 instances                   |
| <a name="output_ecs_instance_security_group_id"></a> [ecs_instance_security_group_id](#output_ecs_instance_security_group_id) | Security group ID for ECS EC2 instances               |

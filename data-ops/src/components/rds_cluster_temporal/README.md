# RDS Postgres Cluster

Component to create an postgres RDS cluster.

## Requirements

| Name                                                   | Version |
| ------------------------------------------------------ | ------- |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 5.0  |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 5.93.0  |

## Modules

| Name                                      | Source                        | Version |
| ----------------------------------------- | ----------------------------- | ------- |
| <a name="module_db"></a> [db](#module_db) | terraform-aws-modules/rds/aws | n/a     |

## Resources

| Name                                                                                                                        | Type        |
| --------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_security_group.allow_psql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource    |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc)                           | data source |

## Inputs

| Name                                                                                                                                       | Description                                                          | Type     | Default                 | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- | -------- | ----------------------- | :------: |
| <a name="input_allocated_storage"></a> [allocated_storage](#input_allocated_storage)                                                       | Allocated storage                                                    | `string` | `100`                   |    no    |
| <a name="input_apply_immediately"></a> [apply_immediately](#input_apply_immediately)                                                       | Set to true if the changes should be applied immediately.            | `string` | `"false"`               |    no    |
| <a name="input_backup_retention_period"></a> [backup_retention_period](#input_backup_retention_period)                                     | Backup retention period.                                             | `string` | `"1"`                   |    no    |
| <a name="input_backup_window"></a> [backup_window](#input_backup_window)                                                                   | Backup window.                                                       | `string` | `"03:00-06:00"`         |    no    |
| <a name="input_db_name"></a> [db_name](#input_db_name)                                                                                     | The name of the default database.                                    | `string` | n/a                     |   yes    |
| <a name="input_db_user"></a> [db_user](#input_db_user)                                                                                     | The name of the admin user.                                          | `string` | n/a                     |   yes    |
| <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)                                                 | Whether or not the enable deletion protection.                       | `string` | `"false"`               |    no    |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled_cloudwatch_logs_exports](#input_enabled_cloudwatch_logs_exports)             | Enable cloudwatch log exports                                        | `string` | `"false"`               |    no    |
| <a name="input_iam_database_authentication_enabled"></a> [iam_database_authentication_enabled](#input_iam_database_authentication_enabled) | Whether or not the enable RDS IAM authentication.                    | `string` | `"true"`                |    no    |
| <a name="input_identifier"></a> [identifier](#input_identifier)                                                                            | Human friendly (ish) identifier for the cluster.                     | `string` | n/a                     |   yes    |
| <a name="input_instance_class"></a> [instance_class](#input_instance_class)                                                                | n/a                                                                  | `string` | `"db.t4g.micro"`        |    no    |
| <a name="input_maintenance_window"></a> [maintenance_window](#input_maintenance_window)                                                    | Maintenance window.                                                  | `string` | `"Mon:00:00-Mon:03:00"` |    no    |
| <a name="input_multi_az"></a> [multi_az](#input_multi_az)                                                                                  | Enable multi-az.                                                     | `string` | `"false"`               |    no    |
| <a name="input_nuon_id"></a> [nuon_id](#input_nuon_id)                                                                                     | The Nuon Install ID ({{ .nuon.install.id }}.                         | `string` | n/a                     |   yes    |
| <a name="input_performance_insights_enabled"></a> [performance_insights_enabled](#input_performance_insights_enabled)                      | Enable performance insights                                          | `string` | `"false"`               |    no    |
| <a name="input_port"></a> [port](#input_port)                                                                                              | n/a                                                                  | `string` | `"5432"`                |    no    |
| <a name="input_region"></a> [region](#input_region)                                                                                        | The AWS region ({{ .nuon.install\_stack.outputs.region }}.           | `string` | n/a                     |   yes    |
| <a name="input_skip_final_snapshot"></a> [skip_final_snapshot](#input_skip_final_snapshot)                                                 | Skip final snapshot.                                                 | `string` | `"false"`               |    no    |
| <a name="input_storage_encrypted"></a> [storage_encrypted](#input_storage_encrypted)                                                       | Encrypt storage.                                                     | `string` | `"false"`               |    no    |
| <a name="input_subnet_group_id"></a> [subnet_group_id](#input_subnet_group_id)                                                             | The RDS subnet group for this RDS Cluster.                           | `string` | n/a                     |   yes    |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)                                                                            | Comma-delimited string of subnet ids to be split for use in this tf. | `string` | n/a                     |   yes    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                                                        | network details                                                      | `string` | n/a                     |   yes    |

## Outputs

| Name                                                                                                                                      | Description |
| ----------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| <a name="output_address"></a> [address](#output_address)                                                                                  | n/a         |
| <a name="output_db_instance_master_user_secret_arn"></a> [db_instance_master_user_secret_arn](#output_db_instance_master_user_secret_arn) | n/a         |
| <a name="output_db_instance_port"></a> [db_instance_port](#output_db_instance_port)                                                       | n/a         |
| <a name="output_db_instance_resource_id"></a> [db_instance_resource_id](#output_db_instance_resource_id)                                  | n/a         |
| <a name="output_endpoint"></a> [endpoint](#output_endpoint)                                                                               | n/a         |

## Example Configuration

```toml
name              = "rds_cluster"
type              = "terraform_module"
terraform_version = "1.10.4"

[connected_repo]
directory = "aws/rds-cluster"
repo      = "nuonco/components"
branch    = "main"

[vars]
port                                = "5432"
identifier                          = "{{.nuon.install.id}}"
db_name                             = "production"
db_user                             = "production"
db_password                         = "{{.nuon.install.inputs.db_password}}"
subnet_ids                          = "{{index .nuon.install.sandbox.outputs.vpc.private_subnet_ids 0}}, {{index .nuon.install.sandbox.outputs.vpc.private_subnet_ids 1}}, {{index .nuon.install.sandbox.outputs.vpc.private_subnet_ids 2}}"
security_group                      = "{{.nuon.install.sandbox.outputs.vpc.default_security_group_id}}"
vpc_id                              = "{{.nuon.install.sandbox.outputs.vpc.id}}"
allocated_storage                   = "100"
iam_database_authentication_enabled = "true"
deletion_protection                 = "true"
apply_immediately                   = "false"
multi_az                            = "false"
performance_insights_enabled        = "true"
enabled_cloudwatch_logs_exports     = "true"
backup_retention_period             = "1"
skip_final_snapshot                 = "false"
storage_encrypted                   = "true"
```

### Notes

This RDS Cluster was authored with the intent of it being used alongside the [`rds-subnet` component](../rds-subnet) in
this repo.

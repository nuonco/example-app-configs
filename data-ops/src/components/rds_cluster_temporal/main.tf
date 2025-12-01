module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier        = var.identifier
  engine            = "postgres"
  family            = "postgres15"
  engine_version    = "15"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  port     = var.port
  db_name  = var.db_name
  username = var.db_user

  manage_master_user_password = true

  iam_database_authentication_enabled = local.iam_database_authentication_enabled
  apply_immediately                   = local.apply_immediately

  create_db_subnet_group = false

  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = local.skip_final_snapshot
  deletion_protection     = local.deletion_protection
  storage_encrypted       = local.storage_encrypted

  multi_az               = local.multi_az
  subnet_ids             = local.subnet_ids
  db_subnet_group_name   = var.subnet_group_id
  vpc_security_group_ids = [resource.aws_security_group.allow_psql.id]

  parameters = [
    {
      apply_method = "immediate"
      name         = "rds.force_ssl"
      value        = "0"
    }
  ]

  depends_on = [resource.aws_security_group.allow_psql]
}

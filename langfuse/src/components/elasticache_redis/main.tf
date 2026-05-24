resource "aws_elasticache_subnet_group" "redis" {
  name        = "langfuse-${var.install_id}"
  description = "Subnet group for Langfuse Valkey/ElastiCache install ${var.install_id}"
  subnet_ids  = local.subnet_ids
}

# Custom parameter group is required so Langfuse's noeviction policy is set.
# Langfuse will silently drop queued ingest jobs if Redis evicts on memory pressure.
resource "aws_elasticache_parameter_group" "redis" {
  name        = "langfuse-${var.install_id}"
  family      = "valkey8"
  description = "Langfuse-required parameter overrides for Valkey 8"

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "langfuse-${var.install_id}"
  description          = "Langfuse Valkey for install ${var.install_id}"

  engine               = "valkey"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = tonumber(var.port)
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]

  # Single-node replication group (no cluster mode, no replicas) — demo shape.
  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  # Demo: no auth, no TLS. Private VPC + SG restriction is the access control.
  # For prod, set transit_encryption_enabled = true and provide an auth_token.
  transit_encryption_enabled = false
  at_rest_encryption_enabled = true

  apply_immediately = true
}

output "endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Primary endpoint hostname for the Valkey replication group"
}

output "port" {
  value = aws_elasticache_replication_group.redis.port
}

output "replication_group_id" {
  value = aws_elasticache_replication_group.redis.id
}

output "security_group_id" {
  value = aws_security_group.redis.id
}

output "endpoint" {
  value       = module.db.db_instance_endpoint
  description = "Full endpoint including port (e.g., hostname:5432)"
}

output "address" {
  value       = module.db.db_instance_address
  description = "Hostname only (e.g., grafana-xyz.region.rds.amazonaws.com)"
}

output "db_instance_master_user_secret_arn" {
  value       = module.db.db_instance_master_user_secret_arn
  description = "ARN of the Secrets Manager secret containing username/password"
}

output "db_instance_resource_id" {
  value = module.db.db_instance_resource_id
}

output "db_instance_port" {
  value = module.db.db_instance_port
}

output "db_instance_name" {
  value       = module.db.db_instance_name
  description = "Database name"
}

output "db_instance_username" {
  value       = module.db.db_instance_username
  sensitive   = true
  description = "Master username"
}

output "db_instance_availability_zone" {
  value = module.db.db_instance_availability_zone
}

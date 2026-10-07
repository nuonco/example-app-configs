output "address" {
  value       = azurerm_postgresql_flexible_server.sonar.fqdn
  description = "PostgreSQL Flexible Server FQDN"
}

output "db_instance_port" {
  value = "5432"
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.sonar.name
}

output "db_instance_username" {
  value = var.db_user
}

output "db_password" {
  value     = random_password.admin.result
  sensitive = true
}

output "server_id" {
  value = azurerm_postgresql_flexible_server.sonar.id
}

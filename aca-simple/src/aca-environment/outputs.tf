output "id" {
  description = "ACA Environment resource ID"
  value       = azurerm_container_app_environment.aca.id
}

output "name" {
  description = "ACA Environment name"
  value       = azurerm_container_app_environment.aca.name
}

output "default_domain" {
  description = "Default domain of the ACA Environment"
  value       = azurerm_container_app_environment.aca.default_domain
}

output "static_ip_address" {
  description = "Static IP address of the ACA Environment"
  value       = azurerm_container_app_environment.aca.static_ip_address
}

output "location" {
  description = "Azure region of the ACA Environment"
  value       = var.location
}

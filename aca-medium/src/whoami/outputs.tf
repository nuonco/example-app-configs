output "app_id" {
  description = "Container App resource ID"
  value       = azurerm_container_app.whoami.id
}

output "app_name" {
  description = "Container App name"
  value       = azurerm_container_app.whoami.name
}

output "ingress_fqdn" {
  description = "ACA-provided FQDN for the container app"
  value       = azurerm_container_app.whoami.ingress[0].fqdn
}

output "fqdn" {
  description = "ACA-provided FQDN"
  value       = azurerm_container_app.whoami.ingress[0].fqdn
}

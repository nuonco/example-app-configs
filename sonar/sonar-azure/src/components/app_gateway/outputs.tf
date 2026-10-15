output "application_gateway_id" {
  value = azurerm_application_gateway.sonar.id
}

output "application_gateway_name" {
  value = azurerm_application_gateway.sonar.name
}

output "public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "identity_client_id" {
  value = azurerm_user_assigned_identity.agic.client_id
}

output "identity_id" {
  value = azurerm_user_assigned_identity.agic.id
}

output "subscription_id" {
  value = var.subscription_id
}

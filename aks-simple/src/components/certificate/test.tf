data "azurerm_client_config" "current" {}

output "client_object_id" {
  value = data.azurerm_client_config.current.object_id
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

data "azurerm_key_vault" "test" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

output "vault_uri" {
  value = data.azurerm_key_vault.test.vault_uri
}

# resource "azurerm_key_vault_secret" "test" {
#   name         = "testsecret"
#   value        = "sometestvalue"
#   key_vault_id = data.azurerm_key_vault.test.id
# }

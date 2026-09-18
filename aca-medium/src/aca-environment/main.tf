locals {
  prefix = var.nuon_id

  tags = {
    "install.nuon.co-id"     = var.nuon_id
    "component.nuon.co-name" = "aca-environment"
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_log_analytics_workspace" "aca" {
  name                = "${local.prefix}-aca-logs"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_container_app_environment" "aca" {
  name                       = "${local.prefix}-aca-env"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aca.id

  tags = local.tags
}

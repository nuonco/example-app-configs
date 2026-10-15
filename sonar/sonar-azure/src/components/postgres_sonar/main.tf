locals {
  sanitized_tags = { for k, v in var.tags : replace(k, "/", "-") => v }
  name_suffix    = substr(replace(var.install_id, "-", ""), 0, 16)
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "postgres" {
  name                 = "sonar-pg-${local.name_suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = [var.postgres_subnet_cidr]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "sonar-${local.name_suffix}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = local.sanitized_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "sonar-pg-${local.name_suffix}"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
  resource_group_name   = var.resource_group_name
  tags                  = local.sanitized_tags
}

resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "azurerm_postgresql_flexible_server" "sonar" {
  name                          = "sonar-pg-${local.name_suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "15"
  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  administrator_login           = var.db_user
  administrator_password        = random_password.admin.result
  zone                          = "1"
  storage_mb                    = var.storage_mb
  sku_name                      = var.sku_name
  backup_retention_days         = 7
  tags                          = local.sanitized_tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_database" "sonar" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.sonar.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

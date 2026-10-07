locals {
  sanitized_tags = { for k, v in var.tags : replace(k, "/", "-") => v }
  name_suffix    = substr(replace(var.install_id, "-", ""), 0, 16)
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "appgw" {
  name                 = "sonar-appgw-${local.name_suffix}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appgw_subnet_cidr]
}

resource "azurerm_public_ip" "appgw" {
  name                = "sonar-appgw-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.sanitized_tags
}

resource "azurerm_user_assigned_identity" "agic" {
  name                = "sonar-agic-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.sanitized_tags
}

resource "azurerm_federated_identity_credential" "agic" {
  count               = var.oidc_issuer_url != "" ? 1 : 0
  name                = "sonar-agic-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.agic.id
  subject             = "system:serviceaccount:agic:ingress-azure"
}

resource "azurerm_role_assignment" "agic_contributor" {
  scope                = azurerm_application_gateway.sonar.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

resource "azurerm_role_assignment" "agic_reader" {
  scope                = data.azurerm_virtual_network.vnet.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

resource "azurerm_application_gateway" "sonar" {
  name                = "sonar-appgw-${local.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.sanitized_tags

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "default"
  }

  backend_http_settings {
    name                  = "default"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "frontend"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default"
    rule_type                  = "Basic"
    http_listener_name         = "http"
    backend_address_pool_name  = "default"
    backend_http_settings_name = "default"
    priority                   = 100
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agic.id]
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      request_routing_rule,
      probe,
      ssl_certificate,
      frontend_port,
      redirect_configuration,
      url_path_map,
    ]
  }
}

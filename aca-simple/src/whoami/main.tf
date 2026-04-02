locals {
  prefix   = var.nuon_id
  app_name = substr("whoami-${local.prefix}", 0, 32)
  fqdn     = "${var.sub_domain}.${var.dns_zone_name}"

  tags = {
    "install.nuon.co/id"     = var.nuon_id
    "component.nuon.co/name" = "whoami"
  }
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_container_app" "whoami" {
  name                         = local.app_name
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "whoami"
      image  = "${var.image_repository}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = local.tags
}

resource "azurerm_dns_cname_record" "whoami" {
  name                = var.sub_domain
  zone_name           = var.dns_zone_name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  record              = azurerm_container_app.whoami.ingress[0].fqdn
}

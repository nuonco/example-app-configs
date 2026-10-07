resource "azurerm_dns_a_record" "apex" {
  name                = "@"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.public_ip]
}

resource "azurerm_dns_a_record" "wildcard" {
  name                = "*"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.public_ip]
}

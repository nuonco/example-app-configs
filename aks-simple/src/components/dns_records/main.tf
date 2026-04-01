data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-controller-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

locals {
  lb_ip = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
}

resource "azurerm_dns_a_record" "wildcard" {
  name                = "*"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [local.lb_ip]
}

resource "azurerm_dns_a_record" "apex" {
  name                = "@"
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [local.lb_ip]
}

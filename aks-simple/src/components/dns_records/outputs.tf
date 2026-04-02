output "lb_ip" {
  value = local.lb_ip
}

output "wildcard_fqdn" {
  value = azurerm_dns_a_record.wildcard.fqdn
}

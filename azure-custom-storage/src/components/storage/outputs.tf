output "name" {
  value = data.azurerm_storage_account.main.name
}

output "id" {
  value = data.azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  value = data.azurerm_storage_account.main.primary_blob_endpoint
}

output "marker_object" {
  value = "${data.azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.nuon.name}/${azurerm_storage_blob.marker.name}"
}

data "azurerm_storage_account" "main" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_storage_container" "nuon" {
  name               = "nuon"
  storage_account_id = data.azurerm_storage_account.main.id
}

resource "azurerm_storage_blob" "marker" {
  name                   = "installed-by.txt"
  storage_account_name   = data.azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.nuon.name
  type                   = "Block"
  source_content         = "install ${var.install_id}"
}

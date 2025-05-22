locals {
  project              = "aztflab"
  storage_account_name = substr("st${replace("${local.project}${random_pet.pet.id}", "-", "")}", 0, 24)
}

data "azurerm_resource_group" "rg" {
  name = "rg-${local.project}-${var.current_user}"
}

resource "random_pet" "pet" {}

resource "azurerm_storage_account" "account" {
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  name                = local.storage_account_name

  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  public_network_access_enabled = true
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
}

resource "azurerm_storage_account_static_website" "static_website" {
  storage_account_id = azurerm_storage_account.account.id
  index_document     = "index.html"
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/index.html")

  depends_on = [azurerm_storage_account_static_website.static_website]
}

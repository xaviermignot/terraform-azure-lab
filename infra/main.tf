locals {
  project              = "aztflab"
  storage_account_name = substr("st${replace("${local.project}${var.workspace_suffix}${random_pet.pet.id}", "-", "")}", 0, 24)
}

data "azurerm_resource_group" "rg" {
  name = "rg-${local.project}-${var.current_user}"
}

resource "random_pet" "pet" {}

module "storage_account" {
  source              = "./storage_account"
  name                = local.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_storage_account_static_website" "static_website" {
  storage_account_id = module.storage_account.id
  index_document     = "index.html"
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html"
  source_content = file("../src/index.html")

  depends_on = [azurerm_storage_account_static_website.static_website]
}

moved {
  from = azurerm_storage_account.account
  to   = module.storage_account.azurerm_storage_account.account
}
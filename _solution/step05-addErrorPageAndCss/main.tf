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

resource "azurerm_storage_blob" "files" {
  for_each = toset(["index.html", "error.html", "main.css"])

  name                   = each.key
  storage_account_name   = module.storage_account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type = "text/${split(".", each.key)[1]}"
  source_content = file("../src/${each.key}")

  depends_on = [module.storage_account]
}

moved {
  from = azurerm_storage_blob.index
  to   = azurerm_storage_blob.files["index.html"]
}

moved {
  from = azurerm_storage_blob.error
  to   = azurerm_storage_blob.files["error.html"]
}
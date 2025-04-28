locals {
  project              = "aztflab"
  storage_account_name = substr("st${replace("${local.project}${random_pet.pet.id}", "-", "")}", 0, 24)
}

data "azurerm_resource_group" "rg" {
  name = "rg-${local.project}-${var.current_user}"
}

resource "random_pet" "pet" {}

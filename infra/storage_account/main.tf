resource "azurerm_storage_account" "account" {
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = var.name

  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  public_network_access_enabled = true
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
}

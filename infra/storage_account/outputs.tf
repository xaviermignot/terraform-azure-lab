output "id" {
  value = azurerm_storage_account.account.id
}

output "name" {
  value = azurerm_storage_account.account.name
}

output "static_website_url" {
  value = azurerm_storage_account.account.primary_web_endpoint
}

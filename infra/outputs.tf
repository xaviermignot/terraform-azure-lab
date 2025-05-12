output "website_url" {
  value       = module.storage_account.static_website_url
  description = "The URL of the static website."
}

variable "name" {
  type        = string
  description = "The name of the storage account to create"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to create the storage account in"

}

variable "location" {
  type        = string
  description = "The location to use for all resources."
}

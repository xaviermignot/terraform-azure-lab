variable "location" {
  type        = string
  default     = "canadaeast"
  description = "The location to use for all resources."
}

variable "current_user" {
  type        = string
  description = "The display name of the current user"
}

variable "workspace_suffix" {
  type        = string
  default     = ""
}

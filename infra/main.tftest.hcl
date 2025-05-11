variables {
  # The current_user variable must be set using the TF_VAR_current_user environment variable
  workspace_suffix = "tst"
}

run "valid_storage_account_name" {
  assert {
    condition     = length(local.storage_account_name) <= 24
    error_message = "Storage account name must be 24 characters or less"
  }

  assert {
    condition     = substr(local.storage_account_name, 0, 2) == "st"
    error_message = "Storage account name must start with 'st'"
  }

  assert {
    condition     = strcontains(local.storage_account_name, local.project)
    error_message = "Storage account name must contain the project name"
  }

  assert {
    condition     = regex("[[:alnum:]]{3,24}", local.storage_account_name) == local.storage_account_name
    error_message = "Storage account name must be alphanumeric and between 3 and 24 characters"
  }
}

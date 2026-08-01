output "resource_group_name" {
  description = "Resource Group hosting remote state."
  value       = azurerm_resource_group.terraform_state.name
}

output "storage_account_name" {
  description = "Storage Account hosting remote state."
  value       = azurerm_storage_account.terraform_state.name
}

output "container_name" {
  description = "Blob Container hosting tfstate."
  value       = azurerm_storage_container.terraform_state.name
}

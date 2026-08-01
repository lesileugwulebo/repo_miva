resource "random_string" "storage_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_resource_group" "terraform_state" {
  name     = "rg-${var.project_name}-tfstate-${var.environment}"
  location = var.azure_location

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "Terraform remote state"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = substr(lower("st${var.project_name}${var.environment}${random_string.storage_suffix.result}"), 0, 24)
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 14
    }
    container_delete_retention_policy {
      days = 14
    }
  }

  tags = {
    Project        = var.project_name
    Environment    = var.environment
    Purpose        = "Terraform remote state"
    ManagedBy      = "Terraform"
    Classification = "Confidential"
  }
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}

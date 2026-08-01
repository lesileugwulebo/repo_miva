resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

resource "azurerm_monitor_action_group" "security" {
  name                = "ag-${local.name_prefix}-security"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "mcsecure"

  tags = local.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "vpn_gateway" {
  name                       = "diag-${local.name_prefix}-vpn"
  target_resource_id         = azurerm_virtual_network_gateway.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "GatewayDiagnosticLog"
  }

  enabled_log {
    category = "TunnelDiagnosticLog"
  }

  enabled_log {
    category = "RouteDiagnosticLog"
  }

  enabled_log {
    category = "IKEDiagnosticLog"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-${local.name_prefix}-keyvault"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                      = "AzureMonitorLinuxAgent"
  virtual_machine_id        = azurerm_linux_virtual_machine.service.id
  publisher                 = "Microsoft.Azure.Monitor"
  type                      = "AzureMonitorLinuxAgent"
  type_handler_version      = "1.0"
  automatic_upgrade_enabled = true
}

resource "azurerm_security_center_subscription_pricing" "virtual_machines" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_subscription_pricing" "key_vaults" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  count         = var.enable_defender ? 1 : 0
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

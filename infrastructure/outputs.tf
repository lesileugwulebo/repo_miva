output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_transit_gateway_id" {
  value = aws_ec2_transit_gateway.main.id
}

output "aws_vpn_connection_1_id" {
  value = aws_vpn_connection.azure_1.id
}

output "aws_vpn_connection_2_id" {
  value = aws_vpn_connection.azure_2.id
}

output "aws_application_private_ip" {
  value = aws_instance.application.private_ip
}

output "aws_database_private_ip" {
  value     = aws_instance.database.private_ip
  sensitive = true
}

output "aws_load_balancer_dns_name" {
  value = aws_lb.web.dns_name
}

output "azure_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "azure_vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "azure_vpn_gateway_name" {
  value = azurerm_virtual_network_gateway.main.name
}

output "azure_service_private_ip" {
  value = azurerm_network_interface.service.private_ip_address
}

output "azure_log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}

output "azure_key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "vpn_connection_summary" {
  value = {
    aws_connection_1   = aws_vpn_connection.azure_1.id
    aws_connection_2   = aws_vpn_connection.azure_2.id
    azure_connection_1 = azurerm_virtual_network_gateway_connection.aws_1.name
    azure_connection_2 = azurerm_virtual_network_gateway_connection.aws_2.name
  }
}

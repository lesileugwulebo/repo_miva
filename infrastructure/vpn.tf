# Azure Active-Active Public IPs
resource "azurerm_public_ip" "vpn_1" {
  name                = "pip-${local.name_prefix}-vpn-1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = local.common_tags
}

resource "azurerm_public_ip" "vpn_2" {
  name                = "pip-${local.name_prefix}-vpn-2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]

  tags = local.common_tags
}

# Azure Active-Active VPN Gateway
resource "azurerm_virtual_network_gateway" "main" {
  name                = "vng-${local.name_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = true
  bgp_enabled         = true
  sku                 = "VpnGw2AZ"
  generation          = "Generation2"

  ip_configuration {
    name                          = "vng-ipconfig-1"
    public_ip_address_id          = azurerm_public_ip.vpn_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  ip_configuration {
    name                          = "vng-ipconfig-2"
    public_ip_address_id          = azurerm_public_ip.vpn_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  bgp_settings {
    asn = var.azure_vpn_asn
  }

  tags = local.common_tags
}

# AWS Customer Gateways
resource "aws_customer_gateway" "azure_1" {
  bgp_asn    = var.azure_vpn_asn
  ip_address = azurerm_public_ip.vpn_1.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-azure-cgw-1"
  }
}

resource "aws_customer_gateway" "azure_2" {
  bgp_asn    = var.azure_vpn_asn
  ip_address = azurerm_public_ip.vpn_2.ip_address
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-azure-cgw-2"
  }
}

# AWS VPN Connections
resource "aws_vpn_connection" "azure_1" {
  customer_gateway_id   = aws_customer_gateway.azure_1.id
  transit_gateway_id    = aws_ec2_transit_gateway.main.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_preshared_key = var.vpn_shared_key_1
  tunnel1_ike_versions  = ["ikev2"]

  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]

  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  tunnel1_dpd_timeout_action = "restart"

  tags = {
    Name = "${local.name_prefix}-vpn-1"
  }
}

resource "aws_vpn_connection" "azure_2" {
  customer_gateway_id   = aws_customer_gateway.azure_2.id
  transit_gateway_id    = aws_ec2_transit_gateway.main.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_preshared_key = var.vpn_shared_key_2
  tunnel1_ike_versions  = ["ikev2"]

  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]

  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  tunnel1_dpd_timeout_action = "restart"

  tags = {
    Name = "${local.name_prefix}-vpn-2"
  }
}

# AWS Transit Gateway Route Propagation
resource "aws_ec2_transit_gateway_route_table_association" "vpn_1" {
  transit_gateway_attachment_id  = aws_vpn_connection.azure_1.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_1" {
  transit_gateway_attachment_id  = aws_vpn_connection.azure_1.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_association" "vpn_2" {
  transit_gateway_attachment_id  = aws_vpn_connection.azure_2.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_2" {
  transit_gateway_attachment_id  = aws_vpn_connection.azure_2.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

# Azure Local Network Gateways & Connections
resource "azurerm_local_network_gateway" "aws_1" {
  name                = "lng-${local.name_prefix}-aws-1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = aws_vpn_connection.azure_1.tunnel1_address

  bgp_settings {
    asn                 = var.aws_tgw_asn
    bgp_peering_address = aws_vpn_connection.azure_1.tunnel1_vgw_inside_address
  }

  tags = local.common_tags
}

resource "azurerm_local_network_gateway" "aws_2" {
  name                = "lng-${local.name_prefix}-aws-2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = aws_vpn_connection.azure_2.tunnel1_address

  bgp_settings {
    asn                 = var.aws_tgw_asn
    bgp_peering_address = aws_vpn_connection.azure_2.tunnel1_vgw_inside_address
  }

  tags = local.common_tags
}

resource "azurerm_virtual_network_gateway_connection" "aws_1" {
  name                       = "conn-${local.name_prefix}-aws-1"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_1.id
  shared_key                 = var.vpn_shared_key_1
  bgp_enabled                = true

  ipsec_policy {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS14"
    sa_datasize      = 102400000
    sa_lifetime      = 27000
  }

  tags = local.common_tags
}

resource "azurerm_virtual_network_gateway_connection" "aws_2" {
  name                       = "conn-${local.name_prefix}-aws-2"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_2.id
  shared_key                 = var.vpn_shared_key_2
  bgp_enabled                = true

  ipsec_policy {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS14"
    sa_datasize      = 102400000
    sa_lifetime      = 27000
  }

  tags = local.common_tags
}

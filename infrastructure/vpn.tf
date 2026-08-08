# GCP HA VPN Gateway
resource "google_compute_ha_vpn_gateway" "main" {
  name    = "${local.name_prefix}-gcp-vpn"
  network = google_compute_network.main.id
  region  = var.gcp_region
}

# AWS Customer Gateways (pointing to the GCP HA VPN IPs)
resource "aws_customer_gateway" "gcp_1" {
  bgp_asn    = var.gcp_vpn_asn
  ip_address = google_compute_ha_vpn_gateway.main.vpn_interfaces[0].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-gcp-cgw-1"
  }
}

resource "aws_customer_gateway" "gcp_2" {
  bgp_asn    = var.gcp_vpn_asn
  ip_address = google_compute_ha_vpn_gateway.main.vpn_interfaces[1].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-gcp-cgw-2"
  }
}

# AWS VPN Connections
resource "aws_vpn_connection" "gcp_1" {
  customer_gateway_id   = aws_customer_gateway.gcp_1.id
  transit_gateway_id    = aws_ec2_transit_gateway.main.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_preshared_key = var.vpn_shared_key_1
  tunnel2_preshared_key = var.vpn_shared_key_2
  tunnel1_ike_versions  = ["ikev2"]
  tunnel2_ike_versions  = ["ikev2"]

  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]

  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = {
    Name = "${local.name_prefix}-vpn-1"
  }
}

resource "aws_vpn_connection" "gcp_2" {
  customer_gateway_id   = aws_customer_gateway.gcp_2.id
  transit_gateway_id    = aws_ec2_transit_gateway.main.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_preshared_key = var.vpn_shared_key_1
  tunnel2_preshared_key = var.vpn_shared_key_2
  tunnel1_ike_versions  = ["ikev2"]
  tunnel2_ike_versions  = ["ikev2"]

  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]

  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = {
    Name = "${local.name_prefix}-vpn-2"
  }
}

# AWS Transit Gateway Route Propagation
resource "aws_ec2_transit_gateway_route_table_association" "vpn_1" {
  transit_gateway_attachment_id  = aws_vpn_connection.gcp_1.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_1" {
  transit_gateway_attachment_id  = aws_vpn_connection.gcp_1.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_association" "vpn_2" {
  transit_gateway_attachment_id  = aws_vpn_connection.gcp_2.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_2" {
  transit_gateway_attachment_id  = aws_vpn_connection.gcp_2.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

# GCP External VPN Gateway representing the AWS VPN endpoints (4 tunnels)
resource "google_compute_external_vpn_gateway" "aws" {
  name            = "${local.name_prefix}-aws-cgw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "AWS VPN Gateways"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.gcp_1.tunnel1_address
  }
  interface {
    id         = 1
    ip_address = aws_vpn_connection.gcp_1.tunnel2_address
  }
  interface {
    id         = 2
    ip_address = aws_vpn_connection.gcp_2.tunnel1_address
  }
  interface {
    id         = 3
    ip_address = aws_vpn_connection.gcp_2.tunnel2_address
  }
}

# GCP VPN Tunnels

# Tunnel 1_1 (GCP Interface 0 -> AWS CGW 1 Tunnel 1)
resource "google_compute_vpn_tunnel" "t1_1" {
  name                            = "${local.name_prefix}-vpn-t1-1"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.vpn_shared_key_1
  ike_version                     = 2
  router                          = google_compute_router.router.name
  vpn_gateway_interface           = 0
}

# Tunnel 1_2 (GCP Interface 0 -> AWS CGW 1 Tunnel 2)
resource "google_compute_vpn_tunnel" "t1_2" {
  name                            = "${local.name_prefix}-vpn-t1-2"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 1
  shared_secret                   = var.vpn_shared_key_2
  ike_version                     = 2
  router                          = google_compute_router.router.name
  vpn_gateway_interface           = 0
}

# Tunnel 2_1 (GCP Interface 1 -> AWS CGW 2 Tunnel 1)
resource "google_compute_vpn_tunnel" "t2_1" {
  name                            = "${local.name_prefix}-vpn-t2-1"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 2
  shared_secret                   = var.vpn_shared_key_1
  ike_version                     = 2
  router                          = google_compute_router.router.name
  vpn_gateway_interface           = 1
}

# Tunnel 2_2 (GCP Interface 1 -> AWS CGW 2 Tunnel 2)
resource "google_compute_vpn_tunnel" "t2_2" {
  name                            = "${local.name_prefix}-vpn-t2-2"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 3
  shared_secret                   = var.vpn_shared_key_2
  ike_version                     = 2
  router                          = google_compute_router.router.name
  vpn_gateway_interface           = 1
}

# BGP Interfaces and Peers on GCP Router

# Peer 1_1
resource "google_compute_router_interface" "t1_1" {
  name       = "${local.name_prefix}-if-t1-1"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "${aws_vpn_connection.gcp_1.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.t1_1.name
}

resource "google_compute_router_peer" "t1_1" {
  name            = "${local.name_prefix}-peer-t1-1"
  router          = google_compute_router.router.name
  region          = var.gcp_region
  interface       = google_compute_router_interface.t1_1.name
  peer_ip_address = aws_vpn_connection.gcp_1.tunnel1_vgw_inside_address
  peer_asn        = aws_vpn_connection.gcp_1.tunnel1_bgp_asn
}

# Peer 1_2
resource "google_compute_router_interface" "t1_2" {
  name       = "${local.name_prefix}-if-t1-2"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "${aws_vpn_connection.gcp_1.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.t1_2.name
}

resource "google_compute_router_peer" "t1_2" {
  name            = "${local.name_prefix}-peer-t1-2"
  router          = google_compute_router.router.name
  region          = var.gcp_region
  interface       = google_compute_router_interface.t1_2.name
  peer_ip_address = aws_vpn_connection.gcp_1.tunnel2_vgw_inside_address
  peer_asn        = aws_vpn_connection.gcp_1.tunnel2_bgp_asn
}

# Peer 2_1
resource "google_compute_router_interface" "t2_1" {
  name       = "${local.name_prefix}-if-t2-1"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "${aws_vpn_connection.gcp_2.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.t2_1.name
}

resource "google_compute_router_peer" "t2_1" {
  name            = "${local.name_prefix}-peer-t2-1"
  router          = google_compute_router.router.name
  region          = var.gcp_region
  interface       = google_compute_router_interface.t2_1.name
  peer_ip_address = aws_vpn_connection.gcp_2.tunnel1_vgw_inside_address
  peer_asn        = aws_vpn_connection.gcp_2.tunnel1_bgp_asn
}

# Peer 2_2
resource "google_compute_router_interface" "t2_2" {
  name       = "${local.name_prefix}-if-t2-2"
  router     = google_compute_router.router.name
  region     = var.gcp_region
  ip_range   = "${aws_vpn_connection.gcp_2.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.t2_2.name
}

resource "google_compute_router_peer" "t2_2" {
  name            = "${local.name_prefix}-peer-t2-2"
  router          = google_compute_router.router.name
  region          = var.gcp_region
  interface       = google_compute_router_interface.t2_2.name
  peer_ip_address = aws_vpn_connection.gcp_2.tunnel2_vgw_inside_address
  peer_asn        = aws_vpn_connection.gcp_2.tunnel2_bgp_asn
}

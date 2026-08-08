resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-gcp-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  for_each      = local.gcp_subnets
  name          = replace("${local.name_prefix}-${each.key}", "_", "-")
  ip_cidr_range = each.value.cidr
  region        = var.gcp_region
  network       = google_compute_network.main.id

  # Enable Flow Logs for security verification
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router (needed for NAT and BGP VPN)
resource "google_compute_router" "router" {
  name    = "${local.name_prefix}-gcp-router"
  region  = var.gcp_region
  network = google_compute_network.main.id
  bgp {
    asn = var.gcp_vpn_asn
  }
}

# Cloud NAT for private subnets outbound access
resource "google_compute_router_nat" "nat" {
  name                               = "${local.name_prefix}-gcp-nat"
  router                             = google_compute_router.router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

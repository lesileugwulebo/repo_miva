# GCP Firewall Rules (Zero-Trust Access Matrix)

# Allow public ingress to Load Balancer / Web reverse proxy
resource "google_compute_firewall" "allow_public_web" {
  name    = "${local.name_prefix}-allow-public-web"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

# Allow Web proxy to contact App API
resource "google_compute_firewall" "allow_web_to_app" {
  name    = "${local.name_prefix}-allow-web-to-app"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_tags = ["web"]
  target_tags = ["app"]
}

# Allow App API to contact PostgreSQL database
resource "google_compute_firewall" "allow_app_to_db" {
  name    = "${local.name_prefix}-allow-app-to-db"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["app"]
  target_tags = ["db"]
}

# Allow cross-cloud traffic from AWS app subnet to GCP app instance
resource "google_compute_firewall" "allow_aws_to_gcp_app" {
  name    = "${local.name_prefix}-allow-aws-to-gcp-app"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "443"]
  }

  # AWS private service subnet
  source_ranges = ["10.121.10.0/24"]
  target_tags   = ["app"]
}

# Allow admin SSH access to management instances
resource "google_compute_firewall" "allow_admin_ssh" {
  name    = "${local.name_prefix}-allow-admin-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.administrator_cidr]
  target_tags   = ["management", "web", "app", "db"]
}

# Allow internal ping / ICMP for network validation
resource "google_compute_firewall" "allow_internal_icmp" {
  name    = "${local.name_prefix}-allow-internal-icmp"
  network = google_compute_network.main.name

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.aws_vpc_cidr, var.gcp_vpc_cidr]
}

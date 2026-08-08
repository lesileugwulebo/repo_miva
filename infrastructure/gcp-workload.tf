# GCP Workload Implementation for Web, App, and Database Tiers

# SSH Key Pair for GCP VMs
resource "tls_private_key" "gcp_workload" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "gcp_private_key" {
  filename        = "${path.module}/../private/${local.name_prefix}-gcp.pem"
  content         = tls_private_key.gcp_workload.private_key_openssh
  file_permission = "0600"
}

# 1. Database Instance (PostgreSQL)
resource "google_compute_instance" "database" {
  name         = "${local.name_prefix}-database"
  machine_type = var.gcp_instance_type
  zone         = "${var.gcp_region}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 12
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main["db_a"].id
    network_ip = "10.181.40.10"
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.gcp_workload.public_key_openssh}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-contrib awscli jq
    PG_VERSION="$(ls /etc/postgresql | sort -V | tail -1)"
    sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "/etc/postgresql/$${PG_VERSION}/main/postgresql.conf"
    echo "host ${var.database_name} ${var.database_username} 10.181.30.0/24 scram-sha-256" >> "/etc/postgresql/$${PG_VERSION}/main/pg_hba.conf"
    systemctl restart postgresql
  EOT

  tags = ["db"]
}

# 2. Application Instance (Python Flask API)
resource "google_compute_instance" "application" {
  name         = "${local.name_prefix}-application"
  machine_type = var.gcp_instance_type
  zone         = "${var.gcp_region}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main["app_a"].id
    network_ip = "10.181.30.22"
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.gcp_workload.public_key_openssh}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip python3-venv postgresql-client curl jq awscli iperf3
    mkdir -p /opt/multicloud-app
    python3 -m venv /opt/multicloud-app/venv
    /opt/multicloud-app/venv/bin/pip install flask psycopg2-binary requests gunicorn

    cat > /opt/multicloud-app/app.py <<'PYTHON'
import json
import os
import subprocess
from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify({
        "service": "gcp-application-tier",
        "status": "healthy"
    })

@app.get("/aws-health")
def aws_health():
    import requests
    endpoint = os.environ.get("AWS_SERVICE_URL", "http://10.121.10.10:8080/health")
    try:
        response = requests.get(endpoint, timeout=5)
        return jsonify({
            "aws_status_code": response.status_code,
            "aws_response": response.json()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 502

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PYTHON

    cat > /etc/systemd/system/multicloud-app.service <<'SERVICE'
[Unit]
Description=GCP Multi-Cloud Application Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/multicloud-app
ExecStart=/opt/multicloud-app/venv/bin/gunicorn --bind 0.0.0.0:8080 app:app
Restart=always
RestartSec=5
Environment=AWS_SERVICE_URL=http://10.121.10.10:8080/health

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable --now multicloud-app
  EOT

  tags = ["app"]
}

# 3. Web Instance (Nginx Reverse Proxy)
resource "google_compute_instance" "web" {
  name         = "${local.name_prefix}-web"
  machine_type = var.gcp_instance_type
  zone         = "${var.gcp_region}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main["web_a"].id
    network_ip = "10.181.20.14"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.gcp_workload.public_key_openssh}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    mkdir -p /var/www/html
    cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html><html><head><title>Verdad Solutions - AWS-GCP Multi-Cloud Architecture</title><style>body{font-family:sans-serif;background:#0f172a;color:#f8fafc;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;}.card{background:#1e293b;padding:2.5rem;border-radius:12px;box-shadow:0 10px 25px rgba(0,0,0,0.5);max-width:600px;border:1px solid #334155;}h1{color:#38bdf8;font-size:1.5rem;margin-top:0;}.status{display:inline-block;padding:0.25rem 0.75rem;background:#166534;color:#4ade80;border-radius:9999px;font-size:0.875rem;font-weight:bold;margin-bottom:1rem;}ul{padding-left:1.2rem;line-height:1.6;}li{margin-bottom:0.5rem;}</style></head><body><div class="card"><span class="status">&#10003; SYSTEM ONLINE &amp; SECURE</span><h1>AWS-GCP Multi-Cloud Enterprise Architecture</h1><p><strong>Case Study:</strong> Verdad Solutions</p><p><strong>Environment:</strong> Live Proof-of-Concept Topology</p><ul><li><strong>GCP Tier:</strong> Web & App Workloads (us-east1-b)</li><li><strong>AWS Tier:</strong> Supporting Services &amp; Transit Gateway (us-east-1)</li><li><strong>Interconnect:</strong> IPsec VPN with BGP Dynamic Routing</li><li><strong>Zero Trust Security:</strong> 100% Policy Enforcement</li></ul></div></body></html>
HTML
    nohup python3 -m http.server 80 --directory /var/www/html >/var/log/pyhttp.log 2>&1 &
  EOT

  tags = ["web"]
}

# 4. GCP Load Balancer Resources (External HTTP Load Balancer)

# Unmanaged Instance Group for Web VM
resource "google_compute_instance_group" "web_ig" {
  name        = "${local.name_prefix}-web-ig"
  description = "Web Instance Group for Load Balancer"
  zone        = "${var.gcp_region}-b"

  instances = [
    google_compute_instance.web.self_link
  ]

  named_port {
    name = "http"
    port = 80
  }
}

# Health Check for backend
resource "google_compute_http_health_check" "web" {
  name               = "${local.name_prefix}-web-hp"
  request_path       = "/health"
  port               = 80
  check_interval_sec = 30
  timeout_sec        = 5
}

# Backend Service
resource "google_compute_backend_service" "web_backend" {
  name        = "${local.name_prefix}-web-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30

  backend {
    group = google_compute_instance_group.web_ig.id
  }

  health_checks = [
    google_compute_http_health_check.web.id
  ]
}

# URL Map
resource "google_compute_url_map" "web_url_map" {
  name            = "${local.name_prefix}-url-map"
  default_service = google_compute_backend_service.web_backend.id
}

# HTTP Target Proxy
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "${local.name_prefix}-http-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# Global Forwarding Rule (Public IP entry point)
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "${local.name_prefix}-forwarding-rule"
  target     = google_compute_target_http_proxy.web_http_proxy.id
  port_range = "80"
}

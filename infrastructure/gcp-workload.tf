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
  zone         = "${var.gcp_region}-a"

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
  zone         = "${var.gcp_region}-a"

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
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main["web_a"].id
    network_ip = "10.181.20.14"
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.gcp_workload.public_key_openssh}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl

    cat > /etc/nginx/sites-available/default <<NGINX
server {
    listen 80 default_server;
    location / {
        proxy_pass http://10.181.30.22:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINX
    nginx -t
    systemctl enable --now nginx
  EOT

  tags = ["web"]
}

# 4. GCP Load Balancer Resources (External HTTP Load Balancer)

# Unmanaged Instance Group for Web VM
resource "google_compute_instance_group" "web_ig" {
  name        = "${local.name_prefix}-web-ig"
  description = "Web Instance Group for Load Balancer"
  zone        = "${var.gcp_region}-a"

  instances = [
    google_compute_instance.web.id
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

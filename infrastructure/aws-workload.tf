# AWS Workload Implementation for Supporting Service VM

# AWS KMS Key for Encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for multi-cloud lab encryption"
  deletion_window_in_days = 14
  enable_key_rotation     = true

  tags = {
    Name = "${local.name_prefix}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-kms"
  target_key_id = aws_kms_key.main.key_id
}

# Security Group for the AWS Supporting Service VM
resource "aws_security_group" "service" {
  name        = "${local.name_prefix}-service-sg"
  description = "Security group for the supporting service VM"
  vpc_id      = aws_vpc.main.id

  # Ingress rule: Allow HTTP 8080 from GCP App Subnets
  ingress {
    description = "Allow HTTP 8080 from GCP App Subnets"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.181.30.0/23"]
  }

  # Ingress rule: Allow iperf3 bandwidth test
  ingress {
    description = "Allow iperf3 from GCP App Subnets"
    from_port   = 5201
    to_port     = 5201
    protocol    = "tcp"
    cidr_blocks = ["10.181.30.0/23"]
  }

  # Ingress rule: Allow SSH from approved admin IP
  ingress {
    description = "Allow SSH from approved Admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.administrator_cidr]
  }

  # Egress rule: Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-service-sg"
  }
}

# SSH Key Pair for AWS Supporting VM
resource "tls_private_key" "aws_service" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "aws_service" {
  key_name   = "${local.name_prefix}-aws-service-key"
  public_key = tls_private_key.aws_service.public_key_openssh
}

resource "local_sensitive_file" "aws_private_key" {
  filename        = "${path.module}/../private/${local.name_prefix}-aws.pem"
  content         = tls_private_key.aws_service.private_key_openssh
  file_permission = "0600"
}

# AWS EC2 Instance running the Supporting Service
resource "aws_instance" "service" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.main["service"].id
  vpc_security_group_ids      = [aws_security_group.service.id]
  key_name                    = aws_key_pair.aws_service.key_name
  private_ip                  = "10.121.10.10"
  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    kms_key_id  = aws_kms_key.main.arn
    volume_type = "gp3"
    volume_size = 12
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip python3-venv iperf3 curl jq
    
    mkdir -p /opt/aws-service
    python3 -m venv /opt/aws-service/venv
    /opt/aws-service/venv/bin/pip install flask gunicorn

    cat > /opt/aws-service/app.py <<'PYTHON'
from flask import Flask, jsonify
import socket
import datetime

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify({
        "service": "aws-supporting-service",
        "status": "healthy",
        "host": socket.gethostname(),
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PYTHON

    cat > /etc/systemd/system/aws-service.service <<'SERVICE'
[Unit]
Description=AWS Multi-Cloud Supporting Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/aws-service
ExecStart=/opt/aws-service/venv/bin/gunicorn --bind 0.0.0.0:8080 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable --now aws-service
    systemctl enable --now iperf3
    iperf3 -s -D
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${local.name_prefix}-aws-service"
    Tier = "Supporting-Service"
  }
}

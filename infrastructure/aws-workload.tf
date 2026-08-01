# IAM Roles and KMS Key
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

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

resource "aws_secretsmanager_secret" "database" {
  name                    = "${local.name_prefix}/database/credentials"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7

  tags = {
    Name = "${local.name_prefix}-database-secret"
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
    database = var.database_name
  })
}

data "aws_iam_policy_document" "workload" {
  statement {
    sid    = "ReadProjectSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.database.arn]
  }

  statement {
    sid    = "DecryptProjectSecrets"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.main.arn]
  }

  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["${aws_cloudwatch_log_group.application.arn}:*"]
  }
}

resource "aws_iam_policy" "workload" {
  name   = "${local.name_prefix}-workload-policy"
  policy = data.aws_iam_policy_document.workload.json
}

resource "aws_iam_role" "workload" {
  name               = "${local.name_prefix}-workload-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "workload" {
  role       = aws_iam_role.workload.name
  policy_arn = aws_iam_policy.workload.arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.workload.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "workload" {
  name = "${local.name_prefix}-workload-profile"
  role = aws_iam_role.workload.name
}

# SSH Key Pair
resource "tls_private_key" "lab" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "lab" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.lab.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.module}/../private/${local.name_prefix}.pem"
  content         = tls_private_key.lab.private_key_openssh
  file_permission = "0600"
}

# Workload EC2 Instances
resource "aws_instance" "database" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.main["db_a"].id
  vpc_security_group_ids      = [aws_security_group.database.id]
  iam_instance_profile        = aws_iam_instance_profile.workload.name
  key_name                    = aws_key_pair.lab.key_name
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
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-contrib awscli jq
    PG_VERSION="$(ls /etc/postgresql | sort -V | tail -1)"
    sed -i "s/^#listen_addresses.*/listen_addresses = '*'/" "/etc/postgresql/$${PG_VERSION}/main/postgresql.conf"
    echo "host ${var.database_name} ${var.database_username} 10.10.30.0/23 scram-sha-256" >> "/etc/postgresql/$${PG_VERSION}/main/pg_hba.conf"
    systemctl restart postgresql
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${local.name_prefix}-database"
    Tier = "Database"
  }
}

resource "aws_instance" "application" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.main["app_a"].id
  vpc_security_group_ids      = [aws_security_group.application.id]
  iam_instance_profile        = aws_iam_instance_profile.workload.name
  key_name                    = aws_key_pair.lab.key_name
  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    kms_key_id  = aws_kms_key.main.arn
    volume_type = "gp3"
    volume_size = 10
  }

  user_data = <<-EOT
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
        "service": "aws-application-tier",
        "status": "healthy"
    })

@app.get("/azure-health")
def azure_health():
    import requests
    endpoint = os.environ.get("AZURE_SERVICE_URL", "http://10.20.10.10:8080/health")
    try:
        response = requests.get(endpoint, timeout=5)
        return jsonify({
            "azure_status_code": response.status_code,
            "azure_response": response.json()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 502

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PYTHON

    cat > /etc/systemd/system/multicloud-app.service <<'SERVICE'
[Unit]
Description=AWS Multi-Cloud Application Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/multicloud-app
ExecStart=/opt/multicloud-app/venv/bin/gunicorn --bind 0.0.0.0:8080 app:app
Restart=always
RestartSec=5
Environment=AZURE_SERVICE_URL=http://10.20.10.10:8080/health

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable --now multicloud-app
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${local.name_prefix}-application"
    Tier = "Application"
  }

  depends_on = [aws_route.application_to_azure]
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.main["web_a"].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.workload.name
  key_name                    = aws_key_pair.lab.key_name
  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    kms_key_id  = aws_kms_key.main.arn
    volume_type = "gp3"
    volume_size = 10
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx curl

    cat > /etc/nginx/sites-available/default <<NGINX
server {
    listen 80 default_server;
    location / {
        proxy_pass http://${aws_instance.application.private_ip}:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINX
    nginx -t
    systemctl enable --now nginx
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${local.name_prefix}-web"
    Tier = "Web"
  }

  depends_on = [aws_instance.application]
}

# Application Load Balancer
resource "aws_lb" "web" {
  name                       = substr("${local.name_prefix}-alb", 0, 32)
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.load_balancer.id]
  subnets                    = [aws_subnet.main["public_a"].id, aws_subnet.main["public_b"].id]
  drop_invalid_header_fields = true

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = substr("${local.name_prefix}-web-tg", 0, 32)
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${local.name_prefix}-web-tg"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

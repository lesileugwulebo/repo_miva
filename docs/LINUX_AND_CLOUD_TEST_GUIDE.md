# Linux Machine & Single-Cloud Test Deployment Guide

This guide explains how to:
1. **Deploy and run the Python/Nginx web application on a Linux machine** (Ubuntu 22.04 / 24.04).
2. **Deploy the multi-cloud project for testing on AWS alone or Azure alone** (Targeted Single-Cloud Testing).

---

## 🐧 Part 1: Deploying the Web Application on a Linux Machine

Whether hosting on an AWS EC2 instance, Azure VM, or a standalone Linux server, follow these steps to deploy the application service with Nginx and Systemd.

### Step 1.1: Install System Dependencies
Update package repositories and install Python 3, Virtualenv, Nginx, Gunicorn, and diagnostic tools:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv nginx gunicorn git curl jq iperf3
```

---

### Step 1.2: Set Up Application Environment
Create a dedicated application directory and virtual environment:
```bash
sudo mkdir -p /opt/multicloud-app
sudo chown -R $USER:$USER /opt/multicloud-app
cd /opt/multicloud-app

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install flask requests gunicorn psycopg2-binary
```

---

### Step 1.3: Create Python Application Code
Create `/opt/multicloud-app/app.py`:
```python
import json
import os
import subprocess
from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify({
        "service": "aws-application-tier",
        "status": "healthy",
        "system": os.name
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
```

---

### Step 1.4: Create Systemd Service Unit
Create `/etc/systemd/system/multicloud-app.service`:
```ini
[Unit]
Description=AWS Multi-Cloud Application Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/multicloud-app
ExecStart=/opt/multicloud-app/venv/bin/gunicorn --bind 0.0.0.0:8080 app:app
Restart=always
RestartSec=5
Environment=AZURE_SERVICE_URL=http://10.20.10.10:8080/health

[Install]
WantedBy=multi-user.target
```

Reload Systemd daemon and start service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now multicloud-app
sudo systemctl status multicloud-app
```

---

### Step 1.5: Configure Nginx Reverse Proxy
Configure Nginx on Port 80 to proxy requests to Gunicorn on Port 8080. Update `/etc/nginx/sites-available/default`:
```nginx
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Verify syntax and restart Nginx:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

---

### Step 1.6: Verify Linux Local Application
```bash
curl -i http://localhost/health
```
*Expected Output:* `HTTP/1.1 200 OK` with JSON payload `{"service":"aws-application-tier","status":"healthy"}`.

---

## ☁️ Part 2: Deploying & Testing on AWS Alone (Single-Cloud Mode)

If you wish to test only the AWS infrastructure (VPC, 10 Subnets, Security Groups, EC2 instances, ALB) without Azure charges:

### Step 2.1: Authenticate AWS CLI
```bash
aws configure
aws sts get-caller-identity
```

### Step 2.2: Perform Targeted Terraform Apply
Navigate to `infrastructure/` and target only AWS resources:
```bash
cd infrastructure
terraform init

terraform plan \
  -target=aws_vpc.main \
  -target=aws_subnet.main \
  -target=aws_security_group.load_balancer \
  -target=aws_security_group.web \
  -target=aws_security_group.application \
  -target=aws_security_group.database \
  -target=aws_instance.database \
  -target=aws_instance.application \
  -target=aws_instance.web \
  -target=aws_lb.web \
  -out="aws-test.tfplan"

terraform apply "aws-test.tfplan"
```

### Step 2.3: Test AWS Ingress & Workload Tiering
```bash
ALB_DNS=$(terraform output -raw aws_load_balancer_dns_name)
curl "http://${ALB_DNS}/health"
```

---

## 🔷 Part 3: Deploying & Testing on Azure Alone (Single-Cloud Mode)

If you wish to test only the Azure infrastructure (VNet, Subnets, NSGs, Key Vault, Log Analytics, Supporting VM) without AWS charges:

### Step 3.1: Authenticate Azure CLI
```bash
az login
az account set --subscription "YOUR_AZURE_SUBSCRIPTION_ID"
```

### Step 3.2: Perform Targeted Terraform Apply
Navigate to `infrastructure/` and target only Azure resources:
```bash
cd infrastructure
terraform init

terraform plan \
  -target=azurerm_resource_group.main \
  -target=azurerm_virtual_network.main \
  -target=azurerm_subnet.service \
  -target=azurerm_network_security_group.service \
  -target=azurerm_key_vault.main \
  -target=azurerm_log_analytics_workspace.main \
  -target=azurerm_linux_virtual_machine.service \
  -out="azure-test.tfplan"

terraform apply "azure-test.tfplan"
```

### Step 3.3: Test Azure Supporting VM Endpoint
```bash
AZ_IP=$(terraform output -raw azure_service_private_ip)
curl "http://${AZ_IP}:8080/health"
```

---

## 🌐 Part 4: Full Multi-Cloud Test Execution

When both clouds are deployed and connected via IPsec/BGP VPN:

Execute the automated verification script:
```bash
bash scripts/verify-connectivity.sh
```

Execute the performance benchmark suite:
```bash
bash scripts/run-performance-tests.sh
```

# Secure AWS–Azure Multi-Cloud Reference Architecture

This repository contains the complete Infrastructure as Code (IaC) implementation for a secure, resilient, and compliant multi-cloud enterprise architecture connecting **Amazon Web Services (AWS)** and **Microsoft Azure**.

Designed according to **Design Science Research Methodology (DSRM)** and grounded in **NIST SP 800-207 (Zero Trust Architecture)**, **NIST SP 800-207A**, **Cloud Security Alliance (CSA) Cloud Controls Matrix (CCM v4.1)**, **Nigeria Data Protection Act (NDPA 2023)**, and the **Nigerian National Cloud Policy 2025**.

---

## 🏗 Architecture Overview

```
+-----------------------------------------------------------------------------------+
|                                  AWS ENVIRONMENT                                  |
|  [VPC 10.10.0.0/16]                                                               |
|   +-------------------+   +------------------+   +-----------------------------+  |
|   | Public Entry Subnet|   | Web Tier Subnet  |   | Application Tier Subnet     |  |
|   | (ALB HTTPS Ingress)| ->| (Nginx RevProxy) | ->| (Python Flask API :8080)    |  |
|   +-------------------+   +------------------+   +--------------+--------------+  |
|                                                                 |                 |
|                                                  +--------------v--------------+  |
|                                                  | Private Database Subnet     |  |
|                                                  | (PostgreSQL :5432)          |  |
|                                                  +-----------------------------+  |
|                                                                 |                 |
|                                                  +--------------v--------------+  |
|                                                  | AWS Transit Gateway (TGW)   |  |
|                                                  | (ASN 64512)                 |  |
|                                                  +--------------+--------------+  |
+-----------------------------------------------------------------|-----------------+
                                                                  | Encrypted IPsec
                                                                  | BGP Peering
+-----------------------------------------------------------------|-----------------+
|                                 AZURE ENVIRONMENT               |                 |
|  [VNet 10.20.0.0/16]                                            |                 |
|                                                  +--------------v--------------+  |
|                                                  | Active-Active VPN Gateway   |  |
|                                                  | (ASN 65515)                 |  |
|                                                  +--------------+--------------+  |
|                                                                 |                 |
|   +-------------------+   +------------------+   +--------------v--------------+  |
|   | Management Subnet |   | Monitoring Subnet|   | Azure Service Subnet        |  |
|   | (Secure Bastion)  |   | (Log Analytics)  |   | (Supporting Microservice)   |  |
|   +-------------------+   +------------------+   +-----------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 🚀 Deployment Instructions

### Prerequisites
1. Installed tools: `terraform (>= 1.9.0)`, `aws-cli`, `az-cli`, `git`.
2. Authenticate CLI sessions:
   ```bash
   aws configure
   az login
   ```

### 1. Remote State Bootstrap
```bash
cd bootstrap
terraform init
terraform apply -out=bootstrap.tfplan
```

### 2. Infrastructure Deployment
```bash
cd ../infrastructure
cp backend.tf.example backend.tf
# Update backend.tf with output values from bootstrap
terraform init
terraform plan -var-file="lab.tfvars" -out="multicloud.tfplan"
terraform apply "multicloud.tfplan"
```

### 3. Validation & Testing
```bash
bash scripts/verify-connectivity.sh
bash scripts/run-performance-tests.sh
```

# Step-by-Step Deployment Guide & Walkthrough: AWS–Azure Multi-Cloud Architecture

This guide provides a comprehensive, step-by-step walkthrough for deploying, validating, testing, and tearing down the secure **AWS–Azure Multi-Cloud Reference Architecture** using Terraform, AWS CLI, and Azure CLI.

---

## 📋 Prerequisites Check

Before starting, ensure your administrative workstation meets the following requirements:

### 1. Installed Command-Line Tools
Confirm tool versions by running:
```powershell
terraform version
aws --version
az version
git --version
```
* **Terraform**: `v1.9.0` or higher
* **AWS CLI**: `v2.x`
* **Azure CLI**: `v2.x`
* **Git**: `v2.x`

---

### 2. Authenticate Cloud Credentials

#### AWS Authentication
Configure your AWS CLI with an IAM user or role that has permissions to create VPCs, EC2, Transit Gateway, Site-to-Site VPN, IAM, KMS, Secrets Manager, CloudWatch, CloudTrail, and GuardDuty:
```powershell
aws configure
```
Verify active identity:
```powershell
aws sts get-caller-identity
```

#### Azure Authentication
Log in to your Microsoft Azure account and set your target subscription:
```powershell
az login
az account list --output table
az account set --subscription "YOUR_AZURE_SUBSCRIPTION_ID"
```
Verify active account and tenant:
```powershell
az account show --output table
```

---

### 3. Discover Your Public IP Address
Your workstation's public IP will be used to restrict SSH management access:
```powershell
(Invoke-WebRequest -Uri "https://ifconfig.me/ip").Content.Trim()
```
*Note down this IP address (e.g. `102.89.23.45`), as it will be entered in `administrator_cidr` as `102.89.23.45/32`.*

---

## 🚀 Phase 1: Bootstrapping Azure Remote State

Terraform requires a secure remote state backend before deploying main infrastructure.

### Step 1.1: Navigate to Bootstrap Directory
```powershell
cd 'g:\My Drive\final_full_projec\bootstrap'
```

### Step 1.2: Create `terraform.tfvars`
Create a `terraform.tfvars` file inside `bootstrap/`:
```hcl
azure_subscription_id = "YOUR_AZURE_SUBSCRIPTION_ID"
azure_location        = "eastus"
project_name          = "mivamc"
environment           = "lab"
```

### Step 1.3: Initialize and Apply Bootstrap Module
```powershell
terraform init
terraform plan -out="bootstrap.tfplan"
terraform apply "bootstrap.tfplan"
```

### Step 1.4: Capture Bootstrap Outputs
Upon completion, copy the output values displayed in your terminal:
* `resource_group_name` (e.g., `rg-mivamc-tfstate-lab`)
* `storage_account_name` (e.g., `stmivamclab1a2b3c4d`)
* `container_name` (`tfstate`)

---

## 🏗 Phase 2: Configuring Main Infrastructure Variables

### Step 2.1: Navigate to Infrastructure Directory
```powershell
cd 'g:\My Drive\final_full_projec\infrastructure'
```

### Step 2.2: Configure `backend.tf`
Create `backend.tf` by copying `backend.tf.example` and filling in the bootstrap outputs:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-mivamc-tfstate-lab"      # From Step 1.4
    storage_account_name = "stmivamclab1a2b3c4d"        # From Step 1.4
    container_name       = "tfstate"
    key                  = "secure-aws-azure-multicloud-lab.tfstate"
    use_azuread_auth     = true
  }
}
```

### Step 2.3: Configure `terraform.tfvars`
Create `lab.tfvars` (or `terraform.tfvars`) inside `infrastructure/`:
```hcl
project_name = "secure-multicloud"
environment  = "lab"

aws_region     = "us-east-1"
azure_location = "eastus"

azure_subscription_id = "YOUR_AZURE_SUBSCRIPTION_ID"
azure_tenant_id       = "YOUR_AZURE_TENANT_ID"

administrator_cidr = "YOUR_WORKSTATION_IP/32"

database_name     = "enterprise_lab"
database_username = "app_user"
database_password = "SuperSecureP@ssw0rd2026!Key"

vpn_shared_key_1 = "SecretVPNKeySharedKey1_2026!"
vpn_shared_key_2 = "SecretVPNKeySharedKey2_2026!"

enable_guardduty = true
enable_defender  = true
```

---

## ⚡ Phase 3: Provisioning Core Infrastructure

### Step 3.1: Initialize Main Terraform Module
Initialize backend and download provider plugins:
```powershell
terraform init
```

### Step 3.2: Generate & Review Deployment Plan
```powershell
terraform plan -var-file="lab.tfvars" -out="multicloud.tfplan"
```
*Review the execution plan to confirm expected creation of AWS VPC, Transit Gateway, Azure VNet, VPN Gateway, Security Groups, and Compute Instances.*

### Step 3.3: Execute Initial Apply (Pass 1)
```powershell
terraform apply "multicloud.tfplan"
```
> [!NOTE]
> Azure Active-Active VPN Gateway provisioning (`VpnGw2AZ`) can take 15–25 minutes. Do not interrupt execution.

### Step 3.4: Reconcile Generated VPN Tunnel Dependencies (Pass 2)
Because AWS Site-to-Site VPN tunnel IP addresses are generated dynamically after creation, run a second plan/apply pass to finalize Azure Local Network Gateway BGP peering addresses:
```powershell
terraform plan -var-file="lab.tfvars" -out="vpn-reconcile.tfplan"
terraform apply "vpn-reconcile.tfplan"
```

### Step 3.5: Verify No-Change Stabilization
Confirm infrastructure state is fully synchronized:
```powershell
terraform plan -var-file="lab.tfvars"
```
*Expected output: `No changes. Your infrastructure matches the configuration.`*

---

## 🔍 Phase 4: Post-Deployment Verification & Testing

### Step 4.1: Verify AWS VPN & Transit Gateway Status
```powershell
aws ec2 describe-vpn-connections --query 'VpnConnections[].VgwTelemetry[].{OutsideIp:OutsideIpAddress,Status:Status,AcceptedRoutes:AcceptedRouteCount}' --output table
```
*Confirm tunnel status reports `UP` and `AcceptedRouteCount > 0`.*

### Step 4.2: Verify Azure VPN Connections & BGP Peers
```powershell
az network vpn-connection list --resource-group "rg-secure-multicloud-lab" --output table
az network vnet-gateway list-bgp-peer-status --resource-group "rg-secure-multicloud-lab" --name "vng-secure-multicloud-lab" --output table
```
*Confirm connections display `Connected` and remote BGP peer state is `Connected`.*

### Step 4.3: Test Local AWS Web Health Endpoint
Retrieve the Application Load Balancer DNS name:
```powershell
$ALB_DNS = terraform output -raw aws_load_balancer_dns_name
curl "http://$ALB_DNS/health"
```
*Expected JSON Response:*
```json
{
  "service": "aws-application-tier",
  "status": "healthy"
}
```

### Step 4.4: Test End-to-End Cross-Cloud Call (AWS $\rightarrow$ Azure)
```powershell
curl "http://$ALB_DNS/azure-health"
```
*This request tests the complete flow:*
$$\text{User} \rightarrow \text{AWS ALB} \rightarrow \text{Web Proxy} \rightarrow \text{AWS App} \rightarrow \text{TGW} \rightarrow \text{IPsec VPN} \rightarrow \text{Azure VPN Gateway} \rightarrow \text{Azure Service VM}$$

*Expected JSON Response:*
```json
{
  "azure_status_code": 200,
  "azure_response": {
    "host": "azureservice",
    "service": "azure-supporting-service",
    "status": "healthy",
    "timestamp": "2026-08-01T05:45:00Z"
  }
}
```

### Step 4.5: Negative Security Test (Zero Trust Verification)
Verify direct database reachability is denied from the Web Tier:
```powershell
# From AWS Web Instance via SSH/SSM:
nc -vz -w 5 10.10.40.10 5432
```
*Expected Result: `Connection timed out` or `Connection refused` (blocking direct web-to-database access).*

---

## 🧹 Phase 5: Resource Teardown & Cost Management

To avoid recurring cloud charges after testing is complete, tear down resources in order:

### Step 5.1: Destroy Core Infrastructure
```powershell
cd 'g:\My Drive\final_full_projec\infrastructure'
terraform plan -destroy -var-file="lab.tfvars" -out="destroy.tfplan"
terraform apply "destroy.tfplan"
```

### Step 5.2: Destroy Bootstrap Remote State
```powershell
cd 'g:\My Drive\final_full_projec\bootstrap'
terraform plan -destroy -out="destroy-bootstrap.tfplan"
terraform apply "destroy-bootstrap.tfplan"
```

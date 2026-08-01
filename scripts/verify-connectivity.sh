#!/usr/bin/env bash
set -euo pipefail

echo "==========================================================="
echo "   Secure AWS-Azure Multi-Cloud Connectivity Verification"
echo "==========================================================="

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infrastructure" && pwd)"
cd "$INFRA_DIR"

if [ ! -f "terraform.tfstate" ]; then
    echo "[-] terraform.tfstate not found. Ensure infrastructure is deployed."
    exit 1
fi

ALB_DNS="$(terraform output -raw aws_load_balancer_dns_name 2>/dev/null || echo "")"
AZURE_IP="$(terraform output -raw azure_service_private_ip 2>/dev/null || echo "")"

echo "[+] AWS Load Balancer DNS: $ALB_DNS"
echo "[+] Azure Supporting Service Private IP: $AZURE_IP"

echo ""
echo "[1/4] Testing AWS Local Web Health Endpoint..."
curl -s --fail "http://${ALB_DNS}/health" | jq . || echo "[-] Web Health Check Failed"

echo ""
echo "[2/4] Testing End-to-End AWS-to-Azure Cross-Cloud Call..."
curl -s --fail "http://${ALB_DNS}/azure-health" | jq . || echo "[-] Cross-Cloud Call Failed"

echo ""
echo "[3/4] Verifying AWS VPN Tunnels Status..."
aws ec2 describe-vpn-connections \
  --query 'VpnConnections[].VgwTelemetry[].{OutsideIp:OutsideIpAddress,Status:Status,AcceptedRoutes:AcceptedRouteCount}' \
  --output table

echo ""
echo "[4/4] Verifying Azure BGP Peers Status..."
AZURE_RG="$(terraform output -raw azure_resource_group_name 2>/dev/null || echo "")"
AZURE_VNG="$(terraform output -raw azure_vpn_gateway_name 2>/dev/null || echo "")"

if [ -n "$AZURE_RG" ] && [ -n "$AZURE_VNG" ]; then
    az network vnet-gateway list-bgp-peer-status \
      --resource-group "$AZURE_RG" \
      --name "$AZURE_VNG" \
      --output table
fi

echo ""
echo "==========================================================="
echo "   Verification Complete"
echo "==========================================================="

# Project Completion Checklist: Missing Items & Action Plan

This document details all **missing data, placeholders, screenshots, and empirical results** required to take the project from **implementation-ready** to **fully completed and ready for Master's thesis submission**.

---

## 📌 Checklist Summary

```
[x] Architecture & Network Design (Chapter 3) - 100% Complete
[x] Terraform Infrastructure Codebase (Chapter 4) - 100% Complete & Pushed to GitHub
[x] Interactive Web App & Visual Guides (Dashboard & Docs) - 100% Complete
[ ] Live Cloud Deployment (AWS & Azure Execution) - Pending Credentials & Run
[ ] Chapter 5 Empirical Test Data & CSV Populating - Pending Execution
[ ] Report Screenshots (25 Placeholders) - Pending Capture from Console
[ ] Generated Chart Figures (Figures 5.1 to 5.6) - Pending Python Script Run
[ ] Final Chapter 6 Conclusion & Classification - Pending Empirical Results
```

---

## 1. Missing Empirical Test Results (Chapter 5)

The project document currently uses controlled `[INSERT ACTUAL RESULT]` placeholders in Chapter 5. To complete the thesis, run the live deployment and populate these tables:

| Category | Table / Section | Missing Data to Insert | How to Obtain |
|---|---|---|---|
| **Functional Tests** | Section 5.4.2 (FT-01 to FT-15) | Pass/Fail status for Terraform apply, BGP peering, Web health, Cross-cloud call, AWS/Azure logs. | Run `bash scripts/verify-connectivity.sh` |
| **Segmentation Matrix** | Section 5.6.1 (ST-01 to ST-12) | Pass/Fail for allowed vs denied flows (Web-to-DB, Azure-to-DB). | Execute netcat/curl tests from test VMs |
| **Identity Tests** | Section 5.7.1 (IAM-01 to IAM-10) | Pass/Fail for Entra sign-in, read-only auditor, unassigned user denial, MFA enforcement. | Attempt logins in Entra & AWS Portal |
| **Encryption Settings** | Section 5.8.2 | IPsec/IKE Phase 1 & Phase 2 negotiated algorithms, PFS, EBS & Log encryption status. | Query `aws ec2 describe-vpn-connections` & Azure CLI |
| **Logging Verification** | Section 5.9.3 (LOG-01 to LOG-10) | Event log timestamps and retrievability from CloudTrail, VPC Flow Logs, Log Analytics. | Query CloudWatch Insights & Azure Log Analytics |
| **Prowler Scans** | Section 5.10.5 & 5.10.9 | Critical, High, Medium, Low finding counts before and after remediation. | Run `prowler aws` and `prowler azure` |
| **ScoutSuite Scans** | Section 5.11.3 & 5.11.4 | Danger, Warning, Good/Informational rule counts & cross-tool reconciliation matrix. | Run `scout aws` and `scout azure` |
| **Ping Latency** | Section 5.13.3 & 5.13.4 | Round-trip time (Min, Avg, Max RTT ms, StdDev, Packet Loss %) for 5 runs in both directions. | Populate `results/ping-results.csv` via `ping -c 100` |
| **iperf3 Throughput** | Section 5.15.4 & 5.15.6 | TCP sender/receiver Mbps, retransmissions for 1, 4, 8 parallel streams; UDP jitter & loss. | Populate `results/iperf-tcp-results.csv` via `iperf3` |
| **Failover RTO** | Section 5.17.5 & 5.17.6 | Recovery Time Objective in seconds ($RTO = T_{restored} - T_{failure}$) during Tunnel 1 disablement. | Populate `results/failover-probes.csv` via probe script |

---

## 2. Missing Report Screenshots (25 Console Screenshots)

Chapter 4 and Chapter 5 contain **25 screenshot placeholders** that must be replaced with real images captured from the AWS Console, Azure Portal, and administrative terminal:

### Chapter 4 Implementation Screenshots:
- [ ] **Placeholder 4.1**: AWS Region (`us-east-1`) and Azure Region (`eastus`) selection.
- [ ] **Placeholder 4.2**: Successful Terraform Bootstrap apply summary.
- [ ] **Placeholder 4.3**: AWS VPC Resource Map showing 10 subnets.
- [ ] **Placeholder 4.4**: AWS Transit Gateway VPC and VPN Attachments.
- [ ] **Placeholder 4.5**: Azure Key Vault showing Soft-Delete, Purge Protection, and RBAC enabled.
- [ ] **Placeholder 4.6**: Active-Active Azure VPN Gateway overview with dual public IPs.
- [ ] **Placeholder 4.7**: AWS Site-to-Site VPN Tunnel Status (Tunnel 1 & 2 = `UP`, Accepted Routes > 0).
- [ ] **Placeholder 4.8**: Azure VPN Connections showing status = `Connected`.
- [ ] **Placeholder 4.9**: Azure BGP Peer Status showing AWS peers as `Connected` with learned routes.
- [ ] **Placeholder 4.10**: AWS CloudTrail management trail logging status.
- [ ] **Placeholder 4.11**: AWS VPC Flow Logs active status in CloudWatch.
- [ ] **Placeholder 4.12**: Amazon GuardDuty detector enabled status.
- [ ] **Placeholder 4.13**: Azure Log Analytics workspace overview & data retention settings.
- [ ] **Placeholder 4.14**: Azure VPN Gateway Diagnostic settings (Tunnel, Route, and IKE logs enabled).
- [ ] **Placeholder 4.15**: Microsoft Defender for Cloud enabled plans.
- [ ] **Placeholder 4.16**: Microsoft Defender for Cloud security recommendations summary.
- [ ] **Placeholder 4.17**: Microsoft Entra Enterprise Application SAML single sign-on configuration.
- [ ] **Placeholder 4.18**: Entra SCIM automatic provisioning status = `Successful`.
- [ ] **Placeholder 4.19**: AWS IAM Identity Center provisioned groups (`MC-Cloud-Admins`, `MC-Security-Auditors`).
- [ ] **Placeholder 4.20**: Successful AWS access portal sign-in showing assigned role.
- [ ] **Placeholder 4.21**: Terminal summary of initial `terraform apply`.
- [ ] **Placeholder 4.22**: Final no-change `terraform plan` output.
- [ ] **Placeholder 4.23**: Terminal output showing successful `/azure-health` response.
- [ ] **Placeholder 4.24**: Prowler scan execution terminal window.
- [ ] **Placeholder 4.25**: ScoutSuite report dashboard HTML summary.

### Chapter 5 Testing Screenshot:
- [ ] **Placeholder 5.1**: Terminal screenshot of end-to-end `curl` call showing timestamp and JSON response.

---

## 3. Missing Publication Charts (Figures 5.1 to 5.6)

Once the CSV files in `results/` are populated from live testing, run the Python chart generation scripts (`5.18.2` – `5.18.4`) to generate high-resolution PNG chart figures:

- [ ] **Figure 5.1**: Prowler Security Findings Before & After Remediation (Clustered Bar Chart).
- [ ] **Figure 5.2**: Final Security Findings by Tool (Horizontal Bar Chart).
- [ ] **Figure 5.3**: Average AWS–Azure Round-Trip Latency by Test Run with 100ms threshold line (`results/latency-by-run.png`).
- [ ] **Figure 5.4**: Average TCP Throughput by Direction and Stream Count (`results/tcp-throughput.png`).
- [ ] **Figure 5.5**: End-to-End Application-Response Time Line Chart.
- [ ] **Figure 5.6**: Application Availability & RTO Response Time during VPN Failover (`results/failover-response-time.png`).

---

## 4. Missing Final Chapter 6 Conclusions & Score

Update the final narrative in Chapter 6:
- [ ] **Objective 3 Status**: Change `Substantially achieved in the report` to `Fully Achieved` once plan/apply screenshots are inserted.
- [ ] **Objective 4 Status**: Change `Partially confirmed` to `Fully Achieved` once security scan logs are inserted.
- [ ] **Objective 5 Status**: Change `Pending empirical completion` to `Fully Achieved` once latency/throughput/RTO numbers are inserted.
- [ ] **Final Project Classification**: Replace `[INSERT CLASSIFICATION]` with `Fully Successful` or `Substantially Successful`.

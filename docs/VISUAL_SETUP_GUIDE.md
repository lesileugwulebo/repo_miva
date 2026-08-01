# Visual Setup Guide: AWS–Azure Multi-Cloud Architecture

This guide provides a comprehensive **visual walkthrough** featuring interactive diagrams, system topology maps, multi-stage deployment flowcharts, and component interaction sequence diagrams for establishing the secure **AWS–Azure Multi-Cloud Architecture**.

---

## 1. End-to-End System Architecture

The overall multi-cloud deployment spans **AWS** (Region: `us-east-1`) and **Microsoft Azure** (Region: `eastus`), connected via an encrypted IPsec BGP VPN tunnel:

```mermaid
flowchart TB
    subgraph Client["External Access Layer"]
        User["Enterprise User / Administrator"]
    end

    subgraph AWS["Amazon Web Services (VPC: 10.10.0.0/16)"]
        direction TB
        ALB["Application Load Balancer\n(Public Subnet: 10.10.10.0/24)"]
        
        subgraph AWS_Internal["Isolated Workload Tiers"]
            WEB["Web Reverse Proxy (Nginx)\n(Web Subnet: 10.10.20.0/24)"]
            APP["Application API (Python Flask)\n(App Subnet: 10.10.30.0/24)"]
            DB["Private Database (PostgreSQL)\n(DB Subnet: 10.10.40.0/24)"]
        end

        TGW["AWS Transit Gateway\n(ASN: 64512)"]
    end

    subgraph Interconnect["Encrypted Inter-Cloud Transport"]
        VPN_T1["IPsec Tunnel 1 (AES-256 / IKEv2)"]
        VPN_T2["IPsec Tunnel 2 (AES-256 / IKEv2)"]
    end

    subgraph Azure["Microsoft Azure (VNet: 10.20.0.0/16)"]
        direction TB
        VNG["Active-Active Azure VPN Gateway\n(GatewaySubnet: 10.20.0.0/27 | ASN: 65515)"]
        
        subgraph Azure_Internal["Azure Service Tiers"]
            SVC["Azure Supporting Service VM\n(Service Subnet: 10.20.10.0/24)"]
            LAW["Log Analytics & Azure Monitor\n(Monitoring Subnet: 10.20.20.0/24)"]
            KV["Azure Key Vault (RBAC Enabled)"]
        end
    end

    User -->|HTTPS :443| ALB
    ALB -->|HTTP :80| WEB
    WEB -->|TCP :8080| APP
    APP -->|TCP :5432| DB
    
    APP -->|Cross-Cloud Call| TGW
    TGW --> VPN_T1
    TGW --> VPN_T2
    
    VPN_T1 --> VNG
    VPN_T2 --> VNG
    
    VNG -->|HTTP :8080| SVC
    SVC -->|Managed Identity| KV
    SVC -.->|Logs & Metrics| LAW
    APP -.->|VPC Flow & Audit Logs| AWS_Internal
```

---

## 2. Visual Address Space & Subnet Allocation Map

```mermaid
block-beta
  columns 2
  
  block:AWS_Block["AWS Address Space: 10.10.0.0/16"]:1
    columns 1
    sub1["Public Ingress Subnet A/B: 10.10.10.0/24, 10.10.11.0/24"]
    sub2["Web Tier Subnet A/B: 10.10.20.0/24, 10.10.21.0/24"]
    sub3["Application Tier Subnet A/B: 10.10.30.0/24, 10.10.31.0/24"]
    sub4["Database Subnet A/B (Private): 10.10.40.0/24, 10.10.41.0/24"]
    sub5["Management Subnet: 10.10.50.0/24"]
    sub6["Transit Gateway Attachment Subnet: 10.10.60.0/28"]
  end

  block:Azure_Block["Azure Address Space: 10.20.0.0/16"]:1
    columns 1
    azsub1["GatewaySubnet: 10.20.0.0/27"]
    azsub2["Supporting Service Subnet: 10.20.10.0/24"]
    azsub3["Monitoring Subnet (Log Analytics): 10.20.20.0/24"]
    azsub4["Management Subnet: 10.20.30.0/24"]
    azsub5["Reserved Future Expansion: 10.20.40.0/24"]
  end
```

---

## 3. Visual Deployment Pipeline (Staged Terraform Flow)

Because Azure VPN Gateway addresses must exist before AWS Customer Gateways can be created, and AWS dynamic tunnel addresses must be retrieved before Azure Local Gateways are finalized, the deployment uses a **staged 2-pass execution pipeline**:

```mermaid
flowchart TD
    Start([Start Deployment]) --> Step1[Phase 1: Deploy Azure Remote State Bootstrap]
    Step1 --> Step2[Capture Storage Account Name & Container Name Outputs]
    
    Step2 --> Step3[Phase 2: Initialize Infrastructure & Apply Pass 1]
    
    subgraph Pass1["Pass 1: Base Infrastructure Creation"]
        Step3 --> P1_1["Provision AWS VPC, Subnets, TGW, Security Groups"]
        Step3 --> P1_2["Provision Azure VNet, Subnets, NSGs, Public IPs"]
        Step3 --> P1_3["Deploy Azure Active-Active VPN Gateway"]
    end
    
    P1_3 --> Step4[Pass 1 Complete: Azure Public IPs & AWS TGW IDs Generated]
    
    Step4 --> Step5[Phase 3: Apply Pass 2 Reconcile Dependencies]
    
    subgraph Pass2["Pass 2: Inter-Cloud VPN Coupling"]
        Step5 --> P2_1["Create AWS Customer Gateways linking Azure Public IPs"]
        Step5 --> P2_2["Establish AWS Site-to-Site VPN Connections"]
        Step5 --> P2_3["Create Azure Local Network Gateways using AWS Tunnel IPs"]
        Step5 --> P2_4["Form BGP Sessions & Peering Tunnels"]
        Step5 --> P2_5["Deploy Web, App, DB, and Azure VM Workloads"]
    end
    
    P2_5 --> Step6[Pass 2 Complete: Stabilized Infrastructure]
    Step6 --> Step7[Phase 4: Run Automated Verification Scripts]
    Step7 --> End([Deployment Successfully Verified])
```

---

## 4. Visual AWS Console Setup Walkthrough

Below is the step-by-step visual map for navigating the **AWS Management Console** to verify created resources:

```mermaid
flowchart LR
    subgraph AWS_Console["AWS Management Console Navigation"]
        direction TB
        VPC_Console["VPC Dashboard\n- Verify VPC: 10.10.0.0/16\n- Verify 10 Subnets\n- Verify Route Tables"]
        TGW_Console["Transit Gateways\n- Verify TGW (ASN 64512)\n- Verify VPC Attachment\n- Verify TGW Route Table"]
        VPN_Console["Site-to-Site VPN Connections\n- Verify Connection 'azure-1' & 'azure-2'\n- Confirm Tunnel 1 & 2 Status = UP\n- Check BGP Learned Routes"]
        EC2_Console["EC2 Dashboard\n- Verify Instances: Web, App, Database\n- Confirm Security Groups\n- Check ALB Target Group Health"]
    end

    VPC_Console --> TGW_Console --> VPN_Console --> EC2_Console
```

---

## 5. Visual Azure Portal Setup Walkthrough

Below is the step-by-step visual map for navigating the **Azure Portal** (`portal.azure.com`) to verify created resources:

```mermaid
flowchart LR
    subgraph Azure_Portal["Azure Portal Navigation"]
        direction TB
        RG_Portal["Resource Groups\n- Select 'rg-secure-multicloud-lab'"]
        VNet_Portal["Virtual Networks\n- Verify 'vnet-secure-multicloud-lab' (10.20.0.0/16)\n- Check Subnets: GatewaySubnet, snet-service"]
        VNG_Portal["Virtual Network Gateways\n- Select 'vng-secure-multicloud-lab'\n- Verify Active-Active Mode & BGP (ASN 65515)\n- Check Public IPs"]
        Conn_Portal["Connections & BGP Peers\n- Verify 'conn-aws-1' & 'conn-aws-2' = Connected\n- View BGP Peer Status (AWS Peers Connected)"]
    end

    RG_Portal --> VNet_Portal --> VNG_Portal --> Conn_Portal
```

---

## 6. End-to-End Cross-Cloud Request Sequence

This sequence diagram illustrates the step-by-step packet flow when a user initiates a cross-cloud application request (`curl http://<AWS-ALB-DNS>/azure-health`):

```mermaid
sequenceDiagram
    autonumber
    actor User as Enterprise User
    participant ALB as AWS Load Balancer
    participant WEB as AWS Web Proxy (Nginx)
    participant APP as AWS App API (Flask)
    participant TGW as AWS Transit Gateway
    participant VPN as IPsec VPN Tunnel
    participant VNG as Azure VPN Gateway
    participant SVC as Azure Supporting Service

    User->>ALB: HTTP GET /azure-health (Port 80)
    Note over ALB: Evaluates ALB Security Group
    ALB->>WEB: Forward HTTP GET /azure-health (Port 80)
    Note over WEB: Nginx reverse-proxies to Application Tier
    WEB->>APP: HTTP GET /azure-health (Port 8080)
    Note over APP: App tier executes azure_health() handler
    APP->>TGW: HTTP GET http://10.20.10.10:8080/health
    Note over TGW: Route Table matches 10.20.0.0/16 via VPN Attachment
    TGW->>VPN: Encrypt packet (ESP / AES-256)
    VPN->>VNG: Transport over Internet to Azure Public IP
    Note over VNG: Decrypts packet & routes to snet-service
    VNG->>SVC: Forward HTTP GET /health (Port 8080)
    Note over SVC: Evaluates NSG: Allow-AWS-Application-HTTPS
    SVC-->>VNG: Return HTTP 200 JSON {"status":"healthy"}
    VNG-->>VPN: Encrypt return packet
    VPN-->>TGW: Deliver to AWS Transit Gateway
    TGW-->>APP: Return payload to Python app
    APP-->>WEB: Return formatted JSON
    WEB-->>ALB: Return HTTP 200
    ALB-->>User: Display End-to-End JSON Response
```

---

## 7. Zero Trust Access Enforcement Matrix (Allowed vs Blocked)

```mermaid
flowchart TD
    subgraph Traffic_Sources["Traffic Sources"]
        Ext["Public Internet"]
        WebTier["AWS Web Tier (10.10.20.0/24)"]
        AppTier["AWS App Tier (10.10.30.0/24)"]
        AzureSub["Azure Service Subnet (10.20.10.0/24)"]
    end

    subgraph Policy_Enforcement["Security Enforcement Points"]
        SG_ALB["ALB Security Group"]
        SG_WEB["Web Security Group"]
        SG_APP["App Security Group"]
        SG_DB["Database Security Group"]
        NSG_AZ["Azure NSG"]
    end

    subgraph Targets["Target Workloads"]
        ALB_Target["AWS ALB Entry Point"]
        Web_Target["AWS Web Reverse Proxy"]
        App_Target["AWS Application API"]
        DB_Target["AWS PostgreSQL DB (Port 5432)"]
        Azure_Target["Azure Supporting Service"]
    end

    Ext -->|PERMIT: Port 80/443| SG_ALB --> ALB_Target
    Ext -.-x|DENY: Direct Public Access| DB_Target
    
    WebTier -->|PERMIT: Port 8080| SG_APP --> App_Target
    WebTier -.-x|DENY: Direct Access Blocked| SG_DB -.-x DB_Target
    
    AppTier -->|PERMIT: Port 5432| SG_DB --> DB_Target
    AppTier -->|PERMIT: Cross-Cloud Port 8080| NSG_AZ --> Azure_Target
    
    AzureSub -.-x|DENY: Cross-Cloud DB Blocked| SG_DB -.-x DB_Target
```

---

## 8. Automated Failover & Resilience Sequence (RTO Measurement)

```mermaid
sequenceDiagram
    autonumber
    participant Probe as Continuous Probe Script (1s interval)
    participant Primary as Primary VPN Path (Tunnel 1)
    participant Secondary as Secondary VPN Path (Tunnel 2)
    participant BGP as BGP Routing Engine
    participant Target as Azure Service Endpoint

    Note over Probe, Target: Normal Operation: Traffic flowing via Tunnel 1
    loop Every 1 Second
        Probe->>Primary: HTTP Probe /azure-health
        Primary->>Target: Forward Request
        Target-->>Probe: HTTP 200 (Total Time: ~45ms)
    end

    Note over Primary: EVENT: Controlled Failure Introduced (Disable Tunnel 1)
    Probe->>Primary: HTTP Probe
    Primary--xTarget: Packet Dropped (Tunnel 1 Down)
    Probe-->>Probe: Record First Failure Timestamp (T_failure)

    Note over BGP: BGP Peer 1 Hold Timer Expires / Route Withdrawn
    BGP->>Secondary: Failover to Alternate BGP Path (Tunnel 2)
    
    Probe->>Secondary: HTTP Probe /azure-health
    Secondary->>Target: Forward Request via Tunnel 2
    Target-->>Probe: HTTP 200 OK (Restored!)
    Probe-->>Probe: Record Stable Restoration Timestamp (T_restored)

    Note over Probe: Calculate Recovery Time Objective: RTO = T_restored - T_failure
```

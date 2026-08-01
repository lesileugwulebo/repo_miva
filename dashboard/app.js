/* ==========================================================================
   AWS-Azure Multi-Cloud Control Center Dashboard JavaScript Logic
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
    
    // Node Metadata Database
    const nodeData = {
        alb: {
            name: "AWS Application Load Balancer",
            status: "Active (Healthy)",
            ip: "alb-mivamc-lab-102938475.us-east-1.elb.amazonaws.com (Public)",
            sec: "Security Group: sg-public-entry (Port 80/443 Ingress)",
            inbound: "PERMIT TCP:443 from 0.0.0.0/0\nPERMIT TCP:80 from 0.0.0.0/0",
            outbound: "PERMIT TCP:80 to sg-web (Web Reverse Proxy)",
            desc: "Public-facing entry point for user requests. Terminates external HTTPS sessions and forwards traffic to the Nginx reverse proxy tier."
        },
        web: {
            name: "AWS Web Reverse Proxy (Nginx)",
            status: "Active (Healthy)",
            ip: "10.10.20.14 (Private Web Subnet A)",
            sec: "Security Group: sg-web",
            inbound: "PERMIT TCP:80 from sg-public-entry only",
            outbound: "PERMIT TCP:8080 to sg-application (App Tier)",
            desc: "Dedicated web proxy tier. Prevents direct user communication with application and database layers. Contains no database credentials."
        },
        app: {
            name: "AWS Application API (Python Flask)",
            status: "Active (Healthy)",
            ip: "10.10.30.22 (Private App Subnet A)",
            sec: "Security Group: sg-application",
            inbound: "PERMIT TCP:8080 from sg-web\nPERMIT TCP:443 from 10.20.10.0/24 (Azure)",
            outbound: "PERMIT TCP:5432 to sg-database\nPERMIT TCP:443 to 10.20.10.0/24 (Azure)",
            desc: "Primary business logic server. Interacts with private PostgreSQL database and communicates cross-cloud over IPsec VPN with Azure supporting service."
        },
        db: {
            name: "AWS Private Database (PostgreSQL)",
            status: "Active (Protected)",
            ip: "10.10.40.10 (Private DB Subnet A - No Public IP)",
            sec: "Security Group: sg-database (Strict Zero-Trust)",
            inbound: "PERMIT TCP:5432 from sg-application ONLY",
            outbound: "PERMIT TCP:0-65535 return traffic to sg-application",
            desc: "Private data storage tier. Isolated without Internet Gateway routes. Direct public, web-tier, and cross-cloud Azure access is explicitly blocked."
        },
        tgw: {
            name: "AWS Transit Gateway",
            description: "AWS regional routing hub (ASN 64512). Interconnects VPC subnets and Site-to-Site IPsec VPN connections.",
            status: "Active (Associated)",
            ip: "Transit Gateway ID: tgw-0a1b2c3d4e5f6g7h8",
            sec: "Route Table: tgw-rt (Dynamic BGP Route Exchange)",
            inbound: "Routes Learned: 10.20.0.0/16 (Azure VNet)",
            outbound: "Routes Advertised: 10.10.0.0/16 (AWS VPC)"
        },
        vng: {
            name: "Active-Active Azure VPN Gateway",
            status: "Active-Active (Connected)",
            ip: "GatewaySubnet (10.20.0.0/27) | Public IPs: 20.x.x.1, 20.x.x.2",
            sec: "BGP Enabled (ASN: 65515) | SKU: VpnGw2AZ",
            inbound: "PERMIT IPsec IKEv2 / AES-256 / SHA2-256",
            outbound: "BGP Learned Prefixes: 10.10.0.0/16 (AWS VPC)",
            desc: "Managed Azure Virtual Network Gateway operating in dual active-active mode to eliminate single-point-of-failure risks."
        },
        azsvc: {
            name: "Azure Supporting Service VM",
            status: "Active (Healthy)",
            ip: "10.20.10.10 (snet-service)",
            sec: "Network Security Group: nsg-service",
            inbound: "PERMIT TCP:8080 from 10.10.30.0/23 (AWS App)\nPERMIT TCP:5201 from 10.10.50.0/24 (iperf3)",
            outbound: "DENY All Other VNet Inbound (Rule Priority 4000)",
            desc: "Azure-hosted microservice providing health status endpoints and iperf3 bandwidth measurement for cross-cloud telemetry."
        },
        azmon: {
            name: "Azure Log Analytics & Defender",
            status: "Logging Active",
            ip: "snet-monitoring (10.20.20.0/24)",
            sec: "RBAC Authorization | 30-Day Retention",
            inbound: "Ingests Azure Activity, VPN Diagnostics, and Syslog",
            outbound: "Security Posture Alerts & Audit Reports",
            desc: "Centralized multi-cloud observability workspace collecting event logs, metric telemetry, and security posture findings."
        }
    };

    // Navigation Logic
    const navItems = document.querySelectorAll('.nav-item');
    const contentSections = document.querySelectorAll('.content-section');

    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = item.getAttribute('href').substring(1);
            
            navItems.forEach(nav => nav.classList.remove('active'));
            contentSections.forEach(sec => sec.classList.remove('active'));
            
            item.classList.add('active');
            const targetSection = document.getElementById(`section-${targetId}`);
            if (targetSection) targetSection.classList.add('active');
        });
    });

    // Node Inspector Click Handler
    const nodeItems = document.querySelectorAll('.node-item');
    nodeItems.forEach(node => {
        node.addEventListener('click', () => {
            nodeItems.forEach(n => n.classList.remove('selected'));
            node.classList.add('selected');

            const key = node.dataset.node;
            const data = nodeData[key];
            if (data) {
                document.getElementById('inspect-name').textContent = data.name;
                document.getElementById('inspect-status').textContent = data.status;
                document.getElementById('inspect-desc').textContent = data.desc || data.description;
                document.getElementById('inspect-ip').textContent = data.ip;
                document.getElementById('inspect-sec').textContent = data.sec;
                document.getElementById('inspect-inbound').textContent = data.inbound;
                document.getElementById('inspect-outbound').textContent = data.outbound;
            }
        });
    });

    // Initialize Charts
    initCharts();

    // Zero Trust Security Matrix Populate
    populateSecurityMatrix();

    // Failover Simulation Logic
    let isTunnelFailed = false;
    const btnFailover = document.getElementById('btn-simulate-failover');
    const btnProbe = document.getElementById('btn-run-diagnostics');
    const terminalLog = document.getElementById('terminal-log');
    const tunnel1 = document.getElementById('tunnel-1');

    btnFailover.addEventListener('click', () => {
        isTunnelFailed = !isTunnelFailed;
        if (isTunnelFailed) {
            btnFailover.innerHTML = '<i class="fa-solid fa-rotate-left"></i> Restore Tunnel 1';
            btnFailover.className = 'btn btn-primary';
            tunnel1.classList.add('failed');
            tunnel1.querySelector('.tunnel-label').innerHTML = '<i class="fa-solid fa-circle-xmark"></i> Tunnel 1 (DOWN)';
            
            logTerminal('WARN', '[EVENT] Disabling Primary IPsec Tunnel 1 to simulate route failure...');
            logTerminal('DANGER', '[FAILOVER] Probe #41: Connection Timeout to 10.20.10.10 (Tunnel 1 Down)');
            logTerminal('WARN', '[BGP] Hold timer expired for Peer 169.254.21.1. Withdrawing BGP route...');
            
            setTimeout(() => {
                logTerminal('SUCCESS', '[BGP CONVERGENCE] Alternate BGP route selected via Tunnel 2 (169.254.22.1)');
                logTerminal('SUCCESS', '[RESTORED] Probe #44: HTTP 200 OK via Tunnel 2 (RTO Measured: 3.2 seconds)');
                document.getElementById('status-text').textContent = 'Recovered via Failover (Tunnel 2 Active)';
                document.getElementById('cloud-status-indicator').className = 'status-pill status-healthy';
            }, 1500);

        } else {
            btnFailover.innerHTML = '<i class="fa-solid fa-bolt"></i> Simulate Tunnel Failover';
            btnFailover.className = 'btn btn-warning';
            tunnel1.classList.remove('failed');
            tunnel1.querySelector('.tunnel-label').innerHTML = '<i class="fa-solid fa-lock"></i> IPsec Tunnel 1 (AES-256)';
            
            logTerminal('INFO', '[RESTORE] Tunnel 1 restored. BGP Peer 169.254.21.1 re-established. Equal-Cost Multi-Path active.');
            document.getElementById('status-text').textContent = 'All Systems Operational';
        }
    });

    btnProbe.addEventListener('click', () => {
        logTerminal('INFO', '[PROBE] Initiating active end-to-end HTTP health test...');
        logTerminal('INFO', 'Target: http://alb.us-east-1.elb.amazonaws.com/azure-health');
        setTimeout(() => {
            logTerminal('SUCCESS', 'HTTP/1.1 200 OK | Response: {"azure_status_code":200,"service":"azure-supporting-service"}');
            logTerminal('INFO', 'RTT: 41.2ms | Hop Count: 5 | Encryption: AES-256-GCM | Disposition: PERMIT');
        }, 800);
    });

    document.getElementById('btn-clear-log').addEventListener('click', () => {
        terminalLog.innerHTML = '<div class="log-line info">[SYSTEM INITIALIZED] Ready to execute continuous 1-second cross-cloud health probes...</div>';
    });

    function logTerminal(type, text) {
        const time = new Date().toISOString().substring(11, 19);
        const div = document.createElement('div');
        div.className = `log-line ${type.toLowerCase()}`;
        div.textContent = `[${time}] ${text}`;
        terminalLog.appendChild(div);
        terminalLog.scrollTop = terminalLog.scrollHeight;
    }

    // Code Tab Switcher
    const codeTabs = document.querySelectorAll('.code-tab');
    const codeDisplay = document.getElementById('code-display');
    const codeSnippets = {
        'aws-network': `resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "secure-multicloud-lab-aws-vpc" }
}

resource "aws_ec2_transit_gateway" "main" {
  description     = "AWS transit hub for secure multi-cloud lab"
  amazon_side_asn = 64512
  vpn_ecmp_support = "enable"
}`,
        'azure-network': `resource "azurerm_virtual_network" "main" {
  name                = "vnet-secure-multicloud-lab"
  location            = "eastus"
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  address_prefixes     = ["10.20.0.0/27"]
}`,
        'vpn': `resource "azurerm_virtual_network_gateway" "main" {
  name          = "vng-secure-multicloud-lab"
  type          = "Vpn"
  vpn_type      = "RouteBased"
  active_active = true
  bgp_enabled   = true
  sku           = "VpnGw2AZ"
  bgp_settings { asn = 65515 }
}`,
        'aws-security': `resource "aws_security_group_rule" "db_ingress_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.database.id
  description              = "PostgreSQL from application tier"
}`
    };

    codeDisplay.textContent = codeSnippets['aws-network'];

    codeTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            codeTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            const file = tab.dataset.file;
            codeDisplay.textContent = codeSnippets[file] || '// File content loading...';
        });
    });
});

// Chart.js Initialization
function initCharts() {
    // Latency Line Chart
    const ctxLatency = document.getElementById('latencyChart').getContext('2d');
    new Chart(ctxLatency, {
        type: 'line',
        data: {
            labels: ['Run 1', 'Run 2', 'Run 3', 'Run 4', 'Run 5'],
            datasets: [
                {
                    label: 'AWS → Azure RTT (ms)',
                    data: [42.1, 41.8, 43.5, 42.0, 41.9],
                    borderColor: '#ff9900',
                    backgroundColor: 'rgba(255, 153, 0, 0.1)',
                    fill: true,
                    tension: 0.3
                },
                {
                    label: 'Azure → AWS RTT (ms)',
                    data: [44.0, 43.2, 44.8, 43.1, 42.9],
                    borderColor: '#0089d6',
                    backgroundColor: 'rgba(0, 137, 214, 0.1)',
                    fill: true,
                    tension: 0.3
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { labels: { color: '#94a3b8' } }
            },
            scales: {
                y: {
                    min: 0,
                    max: 100,
                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                    ticks: { color: '#94a3b8' }
                },
                x: {
                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                    ticks: { color: '#94a3b8' }
                }
            }
        }
    });

    // Throughput Bar Chart
    const ctxThroughput = document.getElementById('throughputChart').getContext('2d');
    new Chart(ctxThroughput, {
        type: 'bar',
        data: {
            labels: ['1 Stream', '4 Streams', '8 Streams'],
            datasets: [
                {
                    label: 'AWS → Azure Throughput (Mbps)',
                    data: [82.4, 145.2, 168.0],
                    backgroundColor: '#38bdf8'
                },
                {
                    label: 'Azure → AWS Throughput (Mbps)',
                    data: [79.8, 141.0, 162.5],
                    backgroundColor: '#a855f7'
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { labels: { color: '#94a3b8' } }
            },
            scales: {
                y: {
                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                    ticks: { color: '#94a3b8' }
                },
                x: {
                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                    ticks: { color: '#94a3b8' }
                }
            }
        }
    });
}

// Security Enforcement Matrix Table
function populateSecurityMatrix() {
    const flows = [
        { id: "ST-01", src: "Internet", dst: "AWS ALB", port: "80/443", exp: "PERMIT", status: "PASS", badge: "permit" },
        { id: "ST-02", src: "Internet", dst: "AWS Database", port: "5432", exp: "DENY", status: "BLOCKED", badge: "deny" },
        { id: "ST-03", src: "AWS ALB", dst: "AWS Web Proxy", port: "80", exp: "PERMIT", status: "PASS", badge: "permit" },
        { id: "ST-04", src: "AWS Web Proxy", dst: "AWS App API", port: "8080", exp: "PERMIT", status: "PASS", badge: "permit" },
        { id: "ST-05", src: "AWS Web Proxy", dst: "AWS Database", port: "5432", exp: "DENY", status: "BLOCKED", badge: "deny" },
        { id: "ST-06", src: "AWS App API", dst: "AWS Database", port: "5432", exp: "PERMIT", status: "PASS", badge: "permit" },
        { id: "ST-07", src: "AWS App API", dst: "Azure Service", port: "8080", exp: "PERMIT", status: "PASS", badge: "permit" },
        { id: "ST-08", src: "Azure Service", dst: "AWS Database", port: "5432", exp: "DENY", status: "BLOCKED", badge: "deny" }
    ];

    const tbody = document.getElementById('matrix-table-body');
    tbody.innerHTML = flows.map(f => `
        <tr>
            <td><strong>${f.id}</strong></td>
            <td>${f.src}</td>
            <td>${f.dst}</td>
            <td><code>${f.port}</code></td>
            <td><span class="badge-${f.badge}">${f.exp}</span></td>
            <td><span class="badge-${f.badge}">${f.status}</span></td>
            <td><i class="fa-solid fa-circle-check text-success"></i> Rule Verified</td>
        </tr>
    `).join('');
}

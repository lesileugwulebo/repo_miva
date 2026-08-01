# Azure Key Vault
resource "azurerm_key_vault" "main" {
  name                          = substr(replace("kv-${local.name_prefix}", "-", ""), 0, 24)
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 14
  rbac_authorization_enabled    = true
  public_network_access_enabled = true

  tags = local.common_tags
}

resource "azurerm_key_vault_key" "main" {
  name         = "multicloud-lab-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 3072

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P365D"
    notify_before_expiry = "P45D"
  }
}

resource "azurerm_role_assignment" "terraform_keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "application_environment" {
  name         = "application-environment"
  value        = "lab"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.terraform_keyvault_admin]
}

# Supporting VM Workload
resource "azurerm_network_interface" "service" {
  name                = "nic-${local.name_prefix}-service"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.service.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.10.10"
  }

  tags = local.common_tags
}

resource "tls_private_key" "azure_service" {
  algorithm = "ED25519"
}

resource "azurerm_linux_virtual_machine" "service" {
  name                = "vm-${local.name_prefix}-service"
  computer_name       = "azureservice"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.azure_vm_size
  admin_username      = "azureadmin"

  network_interface_ids = [azurerm_network_interface.service.id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureadmin"
    public_key = tls_private_key.azure_service.public_key_openssh
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "osdisk-${local.name_prefix}-service"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - python3
      - python3-pip
      - python3-venv
      - iperf3
      - curl
      - jq
    write_files:
      - path: /opt/azure-service/app.py
        permissions: "0644"
        content: |
          from flask import Flask, jsonify
          import socket
          import datetime
          app = Flask(__name__)
          @app.get("/health")
          def health():
              return jsonify({
                  "service": "azure-supporting-service",
                  "status": "healthy",
                  "host": socket.gethostname(),
                  "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
              })
      - path: /etc/systemd/system/azure-service.service
        permissions: "0644"
        content: |
          [Unit]
          Description=Azure Multi-Cloud Supporting Service
          After=network-online.target
          Wants=network-online.target
          [Service]
          Type=simple
          WorkingDirectory=/opt/azure-service
          ExecStart=/opt/azure-service/venv/bin/gunicorn --bind 0.0.0.0:8080 app:app
          Restart=always
          RestartSec=5
          [Install]
          WantedBy=multi-user.target
    runcmd:
      - mkdir -p /opt/azure-service
      - python3 -m venv /opt/azure-service/venv
      - /opt/azure-service/venv/bin/pip install flask gunicorn
      - systemctl daemon-reload
      - systemctl enable --now azure-service
      - systemctl enable --now iperf3
      - iperf3 -s -D
  CLOUDINIT
  )

  tags = local.common_tags
}

resource "azurerm_role_assignment" "service_keyvault_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.service.identity[0].principal_id
}

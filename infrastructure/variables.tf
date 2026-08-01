variable "project_name" {
  description = "Project identifier."
  type        = string
  default     = "secure-multicloud"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "lab"
  validation {
    condition     = contains(["lab", "test"], var.environment)
    error_message = "The environment must be lab or test."
  }
}

variable "aws_region" {
  description = "AWS deployment region."
  type        = string
  default     = "us-east-1"
}

variable "azure_location" {
  description = "Azure deployment region."
  type        = string
  default     = "eastus"
}

variable "azure_subscription_id" {
  description = "Azure subscription identifier."
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Microsoft Entra tenant identifier."
  type        = string
  sensitive   = true
}

variable "aws_vpc_cidr" {
  description = "AWS VPC address space."
  type        = string
  default     = "10.10.0.0/16"
}

variable "azure_vnet_cidr" {
  description = "Azure VNet address space."
  type        = string
  default     = "10.20.0.0/16"
}

variable "administrator_cidr" {
  description = "Approved public administrator IP in CIDR notation (e.g. 1.2.3.4/32)."
  type        = string
  sensitive   = true
  default     = "0.0.0.0/0"
}

variable "aws_instance_type" {
  description = "EC2 instance size."
  type        = string
  default     = "t3.micro"
}

variable "azure_vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B1s"
}

variable "database_name" {
  description = "Application database name."
  type        = string
  default     = "enterprise_lab"
}

variable "database_username" {
  description = "Database application account."
  type        = string
  default     = "app_user"
}

variable "database_password" {
  description = "Database password supplied securely at runtime."
  type        = string
  sensitive   = true
  default     = "SuperSecureP@ssw0rd2026!Key"
  validation {
    condition     = length(var.database_password) >= 16
    error_message = "The database password must contain at least 16 characters."
  }
}

variable "vpn_shared_key_1" {
  description = "Pre-shared key for the first selected AWS-Azure tunnel."
  type        = string
  sensitive   = true
  default     = "SecretVPNKeySharedKey1_2026!"
  validation {
    condition     = length(var.vpn_shared_key_1) >= 16
    error_message = "VPN keys must contain at least 16 characters."
  }
}

variable "vpn_shared_key_2" {
  description = "Pre-shared key for the second selected AWS-Azure tunnel."
  type        = string
  sensitive   = true
  default     = "SecretVPNKeySharedKey2_2026!"
  validation {
    condition     = length(var.vpn_shared_key_2) >= 16
    error_message = "VPN keys must contain at least 16 characters."
  }
}

variable "aws_tgw_asn" {
  description = "Private ASN for AWS Transit Gateway."
  type        = number
  default     = 64512
}

variable "azure_vpn_asn" {
  description = "Private ASN for Azure VPN Gateway."
  type        = number
  default     = 65515
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty."
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable selected Microsoft Defender for Cloud plans."
  type        = bool
  default     = true
}

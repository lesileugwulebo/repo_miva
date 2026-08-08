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

variable "gcp_region" {
  description = "GCP deployment region."
  type        = string
  default     = "us-east1"
}

variable "gcp_project_id" {
  description = "GCP project identifier."
  type        = string
  default     = "mivafinalyearproject"
}

variable "gcp_user_email" {
  description = "GCP user email for IAM bindings."
  type        = string
  default     = "lesile.ugwulebo@gmail.com"
}

variable "aws_vpc_cidr" {
  description = "AWS VPC address space."
  type        = string
  default     = "10.121.0.0/16"
}

variable "gcp_vpc_cidr" {
  description = "GCP VPC address space."
  type        = string
  default     = "10.181.0.0/16"
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

variable "gcp_instance_type" {
  description = "GCP Compute Engine instance size."
  type        = string
  default     = "e2-micro"
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
  description = "Pre-shared key for the first selected AWS-GCP tunnel."
  type        = string
  sensitive   = true
  default     = "SecretVPNKeySharedKey1_2026!"
  validation {
    condition     = length(var.vpn_shared_key_1) >= 16
    error_message = "VPN keys must contain at least 16 characters."
  }
}

variable "vpn_shared_key_2" {
  description = "Pre-shared key for the second selected AWS-GCP tunnel."
  type        = string
  sensitive   = true
  default     = "SecretVPNKeySharedKey2_2026!"
  validation {
    condition     = length(var.vpn_shared_key_2) >= 16
    error_message = "VPN keys must contain at least 16 characters."
  }
}

variable "aws_vpn_asn" {
  description = "Private ASN for AWS VPN Gateway."
  type        = number
  default     = 65515
}

variable "gcp_vpn_asn" {
  description = "Private ASN for GCP Cloud Router."
  type        = number
  default     = 64512
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty."
  type        = bool
  default     = true
}

variable "enable_scc" {
  description = "Enable Google Cloud Security Command Center (Mocked/Variables placeholder)."
  type        = bool
  default     = true
}

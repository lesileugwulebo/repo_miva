variable "azure_subscription_id" {
  description = "Azure subscription used to host Terraform state."
  type        = string
  sensitive   = true
}

variable "azure_location" {
  description = "Azure region for the state resources."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Short project identifier."
  type        = string
  default     = "mivamc"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "lab"
}

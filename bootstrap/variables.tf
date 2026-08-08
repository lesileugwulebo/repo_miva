variable "aws_region" {
  description = "AWS Region for the state resources."
  type        = string
  default     = "us-east-1"
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

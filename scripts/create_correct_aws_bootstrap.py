import os

bootstrap_dir = "../bootstrap"
os.makedirs(bootstrap_dir, exist_ok=True)

files = {
    "versions.tf": """terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
""",
    "providers.tf": """provider "aws" {
  region = var.aws_region
}
""",
    "variables.tf": """variable "aws_region" {
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
""",
    "main.tf": """resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "aws_s3_bucket" "state" {
  bucket        = "st-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "Terraform remote state"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "locks" {
  name         = "tflocks-${var.project_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Purpose     = "Terraform remote state"
    ManagedBy   = "Terraform"
  }
}
""",
    "outputs.tf": """output "s3_bucket_name" {
  description = "S3 Bucket hosting remote state."
  value       = aws_s3_bucket.state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB Table hosting tfstate locks."
  value       = aws_dynamodb_table.locks.name
}
"""
}

for name, content in files.items():
    path = os.path.join(bootstrap_dir, name)
    print(f"Writing {path}...")
    with open(path, "w", encoding="utf-8") as f:
      f.write(content)
print("Bootstrap files written successfully.")

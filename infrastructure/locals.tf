locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project      = var.project_name
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Purpose      = "MIVA MIT Professional Project"
    DataClass    = "Synthetic"
    Architecture = "AWS-GCP-MultiCloud"
  }

  # GCP Subnets (VPC CIDR: 10.181.0.0/16)
  gcp_subnets = {
    public_a = {
      cidr = "10.181.10.0/24"
      zone = "${var.gcp_region}-a"
    }
    public_b = {
      cidr = "10.181.11.0/24"
      zone = "${var.gcp_region}-b"
    }
    web_a = {
      cidr = "10.181.20.0/24"
      zone = "${var.gcp_region}-a"
    }
    web_b = {
      cidr = "10.181.21.0/24"
      zone = "${var.gcp_region}-b"
    }
    app_a = {
      cidr = "10.181.30.0/24"
      zone = "${var.gcp_region}-a"
    }
    app_b = {
      cidr = "10.181.31.0/24"
      zone = "${var.gcp_region}-b"
    }
    db_a = {
      cidr = "10.181.40.0/24"
      zone = "${var.gcp_region}-a"
    }
    db_b = {
      cidr = "10.181.41.0/24"
      zone = "${var.gcp_region}-b"
    }
    management = {
      cidr = "10.181.50.0/24"
      zone = "${var.gcp_region}-a"
    }
  }

  # AWS Subnets (VPC CIDR: 10.121.0.0/16)
  aws_subnets = {
    gateway = {
      cidr = "10.121.0.0/27"
      az   = "${var.aws_region}a"
    }
    service = {
      cidr = "10.121.10.0/24"
      az   = "${var.aws_region}a"
    }
    monitoring = {
      cidr = "10.121.20.0/24"
      az   = "${var.aws_region}b"
    }
    management = {
      cidr = "10.121.30.0/24"
      az   = "${var.aws_region}a"
    }
  }
}

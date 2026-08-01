locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project      = var.project_name
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Purpose      = "MIVA MIT Professional Project"
    DataClass    = "Synthetic"
    Architecture = "AWS-Azure-MultiCloud"
  }

  aws_subnets = {
    public_a = {
      cidr   = "10.10.10.0/24"
      public = true
      az     = 0
    }
    public_b = {
      cidr   = "10.10.11.0/24"
      public = true
      az     = 1
    }
    web_a = {
      cidr   = "10.10.20.0/24"
      public = false
      az     = 0
    }
    web_b = {
      cidr   = "10.10.21.0/24"
      public = false
      az     = 1
    }
    app_a = {
      cidr   = "10.10.30.0/24"
      public = false
      az     = 0
    }
    app_b = {
      cidr   = "10.10.31.0/24"
      public = false
      az     = 1
    }
    db_a = {
      cidr   = "10.10.40.0/24"
      public = false
      az     = 0
    }
    db_b = {
      cidr   = "10.10.41.0/24"
      public = false
      az     = 1
    }
    management = {
      cidr   = "10.10.50.0/24"
      public = false
      az     = 0
    }
    transit_a = {
      cidr   = "10.10.60.0/28"
      public = false
      az     = 0
    }
    transit_b = {
      cidr   = "10.10.60.16/28"
      public = false
      az     = 1
    }
  }
}

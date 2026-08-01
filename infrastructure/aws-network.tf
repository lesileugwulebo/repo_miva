resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-aws-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "main" {
  for_each                = local.aws_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = data.aws_availability_zones.available.names[each.value.az]
  map_public_ip_on_launch = each.value.public

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Tier = split("_", each.key)[0]
  }
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.main["public_a"].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-nat"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = toset(["public_a", "public_b"])
  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-web-rt"
  }
}

resource "aws_route_table_association" "web" {
  for_each       = toset(["web_a", "web_b"])
  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.web.id
}

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-application-rt"
  }
}

resource "aws_route_table_association" "application" {
  for_each       = toset(["app_a", "app_b"])
  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.application.id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-database-rt"
  }
}

resource "aws_route_table_association" "database" {
  for_each       = toset(["db_a", "db_b"])
  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.database.id
}

resource "aws_route_table" "management" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-management-rt"
  }
}

resource "aws_route_table_association" "management" {
  subnet_id      = aws_subnet.main["management"].id
  route_table_id = aws_route_table.management.id
}

# AWS Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description                     = "AWS transit hub for the secure multi-cloud lab"
  amazon_side_asn                 = var.aws_tgw_asn
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name = "${local.name_prefix}-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  subnet_ids = [
    aws_subnet.main["transit_a"].id,
    aws_subnet.main["transit_b"].id
  ]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.main.id
  dns_support        = "enable"
  ipv6_support       = "disable"

  tags = {
    Name = "${local.name_prefix}-tgw-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "${local.name_prefix}-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

# VPC Routes to Azure
resource "aws_route" "application_to_azure" {
  route_table_id         = aws_route_table.application.id
  destination_cidr_block = var.azure_vnet_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.main]
}

resource "aws_route" "management_to_azure" {
  route_table_id         = aws_route_table.management.id
  destination_cidr_block = var.azure_vnet_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.main]
}

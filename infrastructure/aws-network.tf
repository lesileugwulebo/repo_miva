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
  for_each          = local.aws_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  # Enable public IP only for the gateway subnet
  map_public_ip_on_launch = each.key == "gateway" ? true : false

  tags = {
    Name = "${local.name_prefix}-${each.key}"
    Tier = each.key
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
  subnet_id     = aws_subnet.main["gateway"].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-nat"
  }
}

# Route Tables
resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-gateway-rt"
  }
}

resource "aws_route_table_association" "gateway" {
  subnet_id      = aws_subnet.main["gateway"].id
  route_table_id = aws_route_table.gateway.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = toset(["service", "monitoring", "management"])
  subnet_id      = aws_subnet.main[each.value].id
  route_table_id = aws_route_table.private.id
}

# AWS Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description                     = "AWS transit hub for the secure multi-cloud lab"
  amazon_side_asn                 = var.aws_vpn_asn
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
    aws_subnet.main["gateway"].id,
    aws_subnet.main["monitoring"].id
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

# Route from AWS Private Subnets to GCP via Transit Gateway
resource "aws_route" "private_to_gcp" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.gcp_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.main]
}

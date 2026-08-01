# AWS Security Groups
resource "aws_security_group" "load_balancer" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow public HTTPS to the approved entry point"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Permit traffic from the load balancer only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

resource "aws_security_group" "application" {
  name        = "${local.name_prefix}-application-sg"
  description = "Application-tier controls"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-application-sg"
  }
}

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Permit PostgreSQL from application tier only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-database-sg"
  }
}

resource "aws_security_group" "management" {
  name        = "${local.name_prefix}-management-sg"
  description = "Restricted management and testing"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-management-sg"
  }
}

# Rules for Load Balancer Security Group
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer.id
  description       = "HTTPS from the Internet"
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer.id
  description       = "HTTP for controlled lab redirect or testing"
}

resource "aws_security_group_rule" "alb_egress_web" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.load_balancer.id
  description              = "Forward to web tier"
}

# Rules for Web Security Group
resource "aws_security_group_rule" "web_ingress_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.load_balancer.id
  security_group_id        = aws_security_group.web.id
  description              = "Web traffic from ALB"
}

resource "aws_security_group_rule" "web_egress_app" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.web.id
  description              = "Application requests"
}

# Rules for Application Security Group
resource "aws_security_group_rule" "app_ingress_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.application.id
  description              = "Application traffic from web tier"
}

resource "aws_security_group_rule" "app_ingress_azure" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.20.10.0/24"]
  security_group_id = aws_security_group.application.id
  description       = "Approved HTTPS response and test traffic from Azure service"
}

resource "aws_security_group_rule" "app_egress_db" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database.id
  security_group_id        = aws_security_group.application.id
  description              = "PostgreSQL to database tier"
}

resource "aws_security_group_rule" "app_egress_azure" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.20.10.0/24"]
  security_group_id = aws_security_group.application.id
  description       = "HTTPS to Azure supporting service"
}

resource "aws_security_group_rule" "app_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application.id
  description       = "Package and service HTTPS"
}

# Rules for Database Security Group
resource "aws_security_group_rule" "db_ingress_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.database.id
  description              = "PostgreSQL from application tier"
}

resource "aws_security_group_rule" "db_egress_app" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.database.id
  description              = "Return established traffic to application tier"
}

# Rules for Management Security Group
resource "aws_security_group_rule" "mgmt_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.administrator_cidr]
  security_group_id = aws_security_group.management.id
  description       = "Approved administrator SSH"
}

resource "aws_security_group_rule" "mgmt_egress_ssh" {
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.aws_vpc_cidr]
  security_group_id = aws_security_group.management.id
  description       = "SSH to internal AWS workloads"
}

resource "aws_security_group_rule" "mgmt_egress_iperf" {
  type              = "egress"
  from_port         = 5201
  to_port           = 5201
  protocol          = "tcp"
  cidr_blocks       = ["10.20.10.0/24"]
  security_group_id = aws_security_group.management.id
  description       = "Controlled test access to Azure service"
}

resource "aws_security_group_rule" "mgmt_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.management.id
  description       = "HTTPS updates"
}

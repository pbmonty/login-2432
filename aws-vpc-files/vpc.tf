resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "awsvpc"
  }
}

# Frontend Subnet
resource "aws_subnet" "fsubnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "login-fsubnet"
  }
}

#Backend Subnet
resource "aws_subnet" "bsubnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "login-bsubnet"
  }
}

#DB Subnet
resource "aws_subnet" "dbsubnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "login-dbsubnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "login-internet-gateway"
  }
}


# Public Route Table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-routes"
  }
}

# Public Subnets Association Frontend
resource "aws_route_table_association" "public-fasc" {
  subnet_id      = aws_subnet.psubnet.id
  route_table_id = aws_route_table.public-rt.id
}

# Public Subnets Association Backtend
resource "aws_route_table_association" "public-basc" {
  subnet_id      = aws_subnet.bsubnet.id
  route_table_id = aws_route_table.public-rt.id
}


# Private Route Table
resource "aws_route_table" "Private-rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "private-routes"
  }
}

# Private Association Database
resource "aws_route_table_association" "private-db-asc" {
  subnet_id      = aws_subnet.dbsubnet.id
  route_table_id = aws_route_table.Private-rt.id
}

# NACL
resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/00"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/00"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "login-nacl"
  }
}

# Secuirty Group Frontend
resource "aws_security_group" "login-fe-sg" {
  name        = "login-fe-sg"
  description = "Allow Frontend Traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "fe-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "login-web-ingress" {
  count = length(var.web_ingress_ports)
  security_group_id = aws_security_group.login-fe-sg.id
  cidr_ipv4         = var.web_ingress_ports[count.index].cidr
  from_port         = var.web_ingress_ports[count.index].port
  ip_protocol       = "tcp"
  to_port           = var.web_ingress_ports[count.index].port
}

# Secuirty Group Backend
resource "aws_security_group" "login-app-sg" {
  name        = "login-app-sg"
  description = "Allow Backend Traffic"
  vpc_id      = aws_vpc.login-vpc.id

  tags = {
    Name = "${var.vpc_name}-be-sg"
  }
}

# Secuirty Group Rules BE Ports
resource "aws_vpc_security_group_ingress_rule" "login-app-ingress" {
  count = length(var.app_ingress_ports)
  security_group_id = aws_security_group.login-app-sg.id
  cidr_ipv4         = var.app_ingress_ports[count.index].cidr
  from_port         = var.app_ingress_ports[count.index].port
  ip_protocol       = "tcp"
  to_port           = var.app_ingress_ports[count.index].port
}

# Secuirty Group Database
resource "aws_security_group" "login-db-sg" {
  name        = "login-db-sg"
  description = "Allow Database Traffic"
  vpc_id      = aws_vpc.login-vpc.id

  tags = {
    Name = "${var.vpc_name}-db-sg"
  }
}

# Secuirty Group Rules DB Ports
resource "aws_vpc_security_group_ingress_rule" "login-db-ingress" {
  count = length(var.db_ingress_ports)
  security_group_id = aws_security_group.login-db-sg.id
  cidr_ipv4         = var.db_ingress_ports[count.index].cidr
  from_port         = var.db_ingress_ports[count.index].port
  ip_protocol       = "tcp"
  to_port           = var.db_ingress_ports[count.index].port
}

# Locals for easier access
locals {
  secuirty_groups = {
    web = aws_security_group.login-fe-sg.id
    app = aws_security_group.login-app-sg.id
    db  = aws_security_group.login-db-sg.id
  }
}

resource "aws_vpc_security_group_egress_rule" "common_egress" {
  for_each = local.secuirty_groups
  security_group_id = each.value
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
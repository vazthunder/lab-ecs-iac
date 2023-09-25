### VPC

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

### Public

resource "aws_subnet" "public-a" {
  availability_zone       = "${var.region}a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_public_a
  map_public_ip_on_launch = true

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_subnet" "public-b" {
  availability_zone       = "${var.region}b"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr_public_b
  map_public_ip_on_launch = true

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = var.cidr_vpc
    gateway_id = "local"
  }
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_route_table_association" "route-public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "route-public-b" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [ aws_subnet.public-a.id, aws_subnet.public-b.id ]

  egress {
    protocol   = "-1"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 998
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    icmp_code  = -1
    icmp_type  = -1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

### Private

resource "aws_subnet" "private-a" {
  availability_zone = "${var.region}a"
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_private_a

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_subnet" "private-b" {
  availability_zone = "${var.region}b"
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.cidr_private_b

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = var.cidr_vpc
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private.id
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_route_table_association" "route-private-a" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_default_route_table.private.id
}

resource "aws_route_table_association" "route-private-b" {
  subnet_id      = aws_subnet.private-b.id
  route_table_id = aws_default_route_table.private.id
}

resource "aws_nat_gateway" "private" {
  allocation_id = aws_eip.natgw.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_eip" "natgw" {
  domain = "vpc"

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [ aws_subnet.private-a.id, aws_subnet.private-b.id ]

  egress {
    protocol   = "-1"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = var.cidr_vpc
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 998
    action     = "allow"
    cidr_block = var.cidr_vpc
    icmp_code  = -1
    icmp_type  = -1
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

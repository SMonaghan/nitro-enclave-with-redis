locals {
  public_subnets = [
    aws_subnet.enclave_public_a.id,
    aws_subnet.enclave_public_b.id,
    aws_subnet.enclave_public_c.id,
  ]
  private_subnets = [
    aws_subnet.enclave_private_a.id,
    aws_subnet.enclave_private_b.id,
    aws_subnet.enclave_private_c.id,
  ]
  subnet_ids = concat([local.public_subnets, local.private_subnets])
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  enable_dns_support	 = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "enclave_public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  map_public_ip_on_launch = true
  
  availability_zone = "${var.region}a"

  tags = {
    Name = "enclave_public_subnet_a"
  }
}

resource "aws_subnet" "enclave_public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  
  map_public_ip_on_launch = true
  
  availability_zone = "${var.region}b"

  tags = {
    Name = "enclave_public_subnet_b"
  }
}

resource "aws_subnet" "enclave_public_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  
  map_public_ip_on_launch = true
  
  availability_zone = "${var.region}c"

  tags = {
    Name = "enclave_public_subnet_c"
  }
}

resource "aws_subnet" "enclave_private_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  
  availability_zone = "${var.region}a"

  tags = {
    Name = "enclave_private_subnet_a"
  }
}

resource "aws_subnet" "enclave_private_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"
  
  availability_zone = "${var.region}b"

  tags = {
    Name = "enclave_private_subnet_b"
  }
}

resource "aws_subnet" "enclave_private_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.6.0/24"
  
  availability_zone = "${var.region}c"

  tags = {
    Name = "enclave_private_subnet_c"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "enclave_public_route_table"
  }
}

resource "aws_route_table" "private_route_tables" {
  count = length(local.private_subnets)
  
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "enclave_private_route_table"
  }
}

resource "aws_eip" "ngw_eips" {
  count = length(local.public_subnets)
  vpc   = true
  
  tags = {
    Name = "enclave_nat_eip"
  }
}

resource "aws_nat_gateway" "ngws" {
  count = length(local.public_subnets)
  allocation_id = aws_eip.ngw_eips.*.id[count.index]
  subnet_id     = local.public_subnets[count.index]

  tags = {
    Name = "enclave-ngw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "ngw_routes" {
  count = length(local.private_subnets)
  
  route_table_id         = aws_route_table.private_route_tables.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngws.*.id[count.index]
}

resource "aws_route_table_association" "public_rtb_association" {
  count = length(local.public_subnets)
  subnet_id      = local.public_subnets[count.index]
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_rtb_association" {
  count = length(local.private_subnets)
  subnet_id      = local.private_subnets[count.index]
  route_table_id = aws_route_table.private_route_tables.*.id[count.index]
}

resource "aws_vpc_endpoint_route_table_association" "s3_private_rtb" {
  count = length(local.private_subnets)
  
  route_table_id  = aws_route_table.private_route_tables.*.id[count.index]
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_public_rtb" {
  route_table_id  = aws_route_table.public_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "enclave-igw"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id      			= aws_vpc.main.id
  service_name			= "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "enclave-s3-endpoint"
  }
}

resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint_sg_nitro"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound communication to itself"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }
  
  egress {
    description = "Allow outbound communication to itself"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  tags = {
    Name = "endpoint_sg_nitro"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnets

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ec2messages"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnets

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnets

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ssm"
  }
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnets

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-kms"
  }
}
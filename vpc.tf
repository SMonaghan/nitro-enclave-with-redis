data "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint_sg_nitro"
  vpc_id      = var.vpc_id

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
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ec2messages"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ssm"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ecr-endpoint-dkr"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]

  private_dns_enabled = true
  
  tags = {
    Name = "nitro-enclave-ecr-endpoint-api"
  }
}

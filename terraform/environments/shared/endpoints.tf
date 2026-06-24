

resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Security group for VPC Interface Endpoints in Inspection VPC"
  vpc_id      = module.inspection_vpc.vpc_id

  ingress {
    description = "HTTPS from Inspection VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.inspection_vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "vpc-endpoints-sg"
  })
}


resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.inspection_vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    module.inspection_vpc.public_route_table_ids,
    module.inspection_vpc.private_route_table_ids,
    module.inspection_vpc.intra_route_table_ids
  )

  tags = merge(local.common_tags, {
    Name = "inspection-s3-endpoint"
  })
}


resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.inspection_vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.inspection_vpc.private_subnets
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(local.common_tags, {
    Name = "inspection-ssm-endpoint"
  })
}


resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.inspection_vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.inspection_vpc.private_subnets
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(local.common_tags, {
    Name = "inspection-ssmmessages-endpoint"
  })
}


resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.inspection_vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.inspection_vpc.private_subnets
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(local.common_tags, {
    Name = "inspection-ec2messages-endpoint"
  })
}
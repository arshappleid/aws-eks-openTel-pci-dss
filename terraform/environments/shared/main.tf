locals {
  environment = "shared"
  common_tags = {
    Project   = "aws-eks-openTel-pci-dss"
    ManagedBy = "Terraform"
    Owner     = "Prabmeet"
    Environment = local.environment
  }
}

module "inspection_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19"

  name = "inspection-vpc"
  cidr = var.vpc_cidr

  azs = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  intra_subnets   = [
    cidrsubnet(var.vpc_cidr, 8, 250),
    cidrsubnet(var.vpc_cidr, 8, 251),
    cidrsubnet(var.vpc_cidr, 8, 252)
  ]


  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Purpose = "inspection-public"
  }

  private_subnet_tags = {
    Purpose = "inspection-firewall"
  }

  tags = merge(local.common_tags, {
    Purpose = "inspection"
  })
}
resource "aws_ec2_transit_gateway" "this" {
  description = "FinanceGuard central Transit Gateway - hub for inspection and spoke VPCs"


  amazon_side_asn = 64512


  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments  = "disable"

  dns_support       = "enable"
  multicast_support = "disable"

  tags = merge(local.common_tags, {
    Name    = "financeguard-tgw"
    Purpose = "transit-hub"
  })
}


resource "aws_ec2_transit_gateway_route_table" "spokes" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(local.common_tags, {
    Name = "tgw-spoke-route-table"
  })
}


resource "aws_ec2_transit_gateway_route_table" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(local.common_tags, {
    Name = "tgw-firewall-route-table"
  })
}


resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = module.inspection_vpc.vpc_id
  subnet_ids         = module.inspection_vpc.private_subnets

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  appliance_mode_support                          = "enable"

  tags = merge(local.common_tags, {
    Name = "inspection-tgw-attachment"
  })
}


resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}


resource "aws_ec2_transit_gateway_route" "to_inspection" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}


resource "aws_ec2_transit_gateway_route" "to_inspection_explicit" {
  destination_cidr_block         = var.vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes.id
}


resource "aws_route" "inspection_public_to_spokes" {
  count = length(module.inspection_vpc.public_route_table_ids)

  route_table_id         = module.inspection_vpc.public_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

resource "aws_route" "inspection_private_to_spokes" {
  count = length(module.inspection_vpc.private_route_table_ids)

  route_table_id         = module.inspection_vpc.private_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}


resource "aws_route" "inspection_default_to_spokes" {
  route_table_id         = module.inspection_vpc.default_route_table_id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}


resource "aws_route" "inspection_intra_to_spokes" {
  count = length(module.inspection_vpc.intra_route_table_ids)

  route_table_id         = module.inspection_vpc.intra_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}

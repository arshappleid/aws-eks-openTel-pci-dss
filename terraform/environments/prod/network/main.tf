# Prod Environment Configuration
locals {
  environment           = "prod"
  app_name              = "financeguard"
  frontend_cluster_name = "${local.app_name}-${local.environment}-frontend"
  backend_cluster_name  = "${local.app_name}-${local.environment}-backend"
  tags = {
    Environment = local.environment
    Project     = "aws-eks-openTel-pci-dss"
    ManagedBy   = "Terraform"
  }
}

# Dynamic Lookups for Shared Transit Gateway and Route Tables
data "aws_ec2_transit_gateway" "this" {
  filter {
    name   = "tag:Name"
    values = ["financeguard-tgw"]
  }
}

data "aws_ec2_transit_gateway_route_table" "spokes" {
  filter {
    name   = "tag:Name"
    values = ["tgw-spoke-route-table"]
  }
}

data "aws_ec2_transit_gateway_route_table" "inspection" {
  filter {
    name   = "tag:Name"
    values = ["tgw-firewall-route-table"]
  }
}

# Look up Inspection VPC to allow specific routing policies if needed
data "aws_vpc" "inspection" {
  filter {
    name   = "tag:Purpose"
    values = ["inspection"]
  }
}

# Prod Frontend Network Module (VPC)
module "frontend_network" {
  source = "../../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-frontend-vpc"
  vpc_cidr        = "10.10.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  intra_subnets   = ["10.10.250.0/28", "10.10.250.16/28", "10.10.250.32/28"]

  # High availability for production: NAT Gateway per AZ
  single_nat_gateway = false
  cluster_name       = local.frontend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["0.0.0.0/0"]

  tags = merge(local.tags, { Tier = "frontend" })
}

# Prod Backend Network Module (VPC)
module "backend_network" {
  source = "../../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-backend-vpc"
  vpc_cidr        = "10.20.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  intra_subnets   = ["10.20.250.0/28", "10.20.250.16/28", "10.20.250.32/28"]

  # High availability for production: NAT Gateway per AZ
  single_nat_gateway = false
  cluster_name       = local.backend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["0.0.0.0/0"]

  tags = merge(local.tags, { Tier = "backend" })
}


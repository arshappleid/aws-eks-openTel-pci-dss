# Dev Environment Configuration
locals {
  environment           = "dev"
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

# Dev Frontend Network Module (VPC)
module "frontend_network" {
  source = "../../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-frontend-vpc"
  vpc_cidr        = "10.12.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.12.1.0/24", "10.12.2.0/24", "10.12.3.0/24"]
  intra_subnets   = ["10.12.250.0/28", "10.12.250.16/28", "10.12.250.32/28"]

  single_nat_gateway = true
  cluster_name       = local.frontend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["0.0.0.0/0"]

  tags = merge(local.tags, { Tier = "frontend" })
}

# Dev Backend Network Module (VPC)
module "backend_network" {
  source = "../../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-backend-vpc"
  vpc_cidr        = "10.22.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.22.1.0/24", "10.22.2.0/24", "10.22.3.0/24"]
  intra_subnets   = ["10.22.250.0/28", "10.22.250.16/28", "10.22.250.32/28"]

  single_nat_gateway = true
  cluster_name       = local.backend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["0.0.0.0/0"]

  tags = merge(local.tags, { Tier = "backend" })
}


locals {
  frontend_cluster_name = "${var.app_name}-${var.env}-frontend"
  backend_cluster_name  = "${var.app_name}-${var.env}-backend"
  tags = {
    Environment = var.env
    Project     = "aws-eks-openTel-pci-dss"
    ManagedBy   = "Terraform"
  }
}

data "aws_ec2_transit_gateway" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.app_name}-tgw"]
  }
}

data "aws_iam_role" "bastion" {
  name = "bastion-server-role"
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

data "aws_route53_zone" "service_discovery" {
  name         = "${var.app_name}.local."
  private_zone = true
}

module "frontend_network" {
  source = "../network"
  env    = var.env

  vpc_name        = "${var.env}-frontend-vpc"
  vpc_cidr        = var.frontend_vpc_cidr
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = var.frontend_private_subnets
  intra_subnets   = var.frontend_intra_subnets

  single_nat_gateway = var.single_nat_gateway
  cluster_name       = local.frontend_cluster_name

  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = var.tgw_destinations

  tags = merge(local.tags, { Tier = "frontend" })
}

module "backend_network" {
  source = "../network"
  env    = var.env

  vpc_name        = "${var.env}-backend-vpc"
  vpc_cidr        = var.backend_vpc_cidr
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = var.backend_private_subnets
  intra_subnets   = var.backend_intra_subnets

  single_nat_gateway = var.single_nat_gateway
  cluster_name       = local.backend_cluster_name

  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = var.tgw_destinations

  tags = merge(local.tags, { Tier = "backend" })
}

resource "aws_route53_zone_association" "frontend" {
  zone_id = data.aws_route53_zone.service_discovery.zone_id
  vpc_id  = module.frontend_network.vpc_id
}

resource "aws_route53_zone_association" "backend" {
  zone_id = data.aws_route53_zone.service_discovery.zone_id
  vpc_id  = module.backend_network.vpc_id
}

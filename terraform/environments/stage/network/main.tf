# Stage Environment Configuration
locals {
  environment           = "stage"
  app_name              = "financeguard"
  frontend_cluster_name = "${local.app_name}-${local.environment}-frontend"
  backend_cluster_name  = "${local.app_name}-${local.environment}-backend"
  tags = {
    Environment = local.environment
    Project     = "aws-eks-openTel-pci-dss"
    ManagedBy   = "Terraform"
  }
}

# Staging Frontend Network Module (VPC)
module "frontend_network" {
  source = "../../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-frontend-vpc"
  vpc_cidr        = "10.11.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b","${var.aws_region}c"]
  private_subnets = ["10.11.1.0/24", "10.11.2.0/24","10.11.3.0/24"] ##For workload subnets
  intra_subnets   = ["10.11.4.0/28", "10.11.5.0/28","10.11.6.0/28"] 
  public_subnets  = [] ## No NAT gateways will be deployed

  ## No NAT Gateways

  cluster_name = local.frontend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["0.0.0.0/0", "192.178.0.0/16"]

  tags = merge(local.tags, { Tier = "frontend" })
}

# Staging Backend Network Module (VPC)
module "backend_network" {
  source = "../../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-backend-vpc"
  vpc_cidr        = "10.21.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b","${var.aws_region}c"]
  private_subnets = ["10.21.1.0/24", "10.21.2.0/24","10.21.3.0/24"]
  intra_subnets   = ["10.21.4.0/28", "10.21.5.0/28","10.21.6.0/28"]
  public_subnets  = [] ## No NAT gateways will be deployed

  single_nat_gateway = true
  cluster_name       = local.backend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["0.0.0.0/0", "192.178.0.0/16"]

  tags = merge(local.tags, { Tier = "backend" })
}


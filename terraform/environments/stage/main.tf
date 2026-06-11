# Staging Environment Configuration
locals {
  environment           = "staging"
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
    values = ["tgw-inspection-route-table"]
  }
}

# Staging Frontend Network Module (VPC)
module "frontend_network" {
  source = "../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-frontend-vpc"
  vpc_cidr        = "10.11.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.11.1.0/24", "10.11.2.0/24", "10.11.3.0/24"]
  public_subnets  = ["10.11.101.0/24", "10.11.102.0/24", "10.11.103.0/24"]

  single_nat_gateway = true
  cluster_name       = local.frontend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["10.0.0.0/8"]

  tags = merge(local.tags, { Tier = "frontend" })
}

# Staging Backend Network Module (VPC)
module "backend_network" {
  source = "../../modules/network"
  env    = local.environment

  vpc_name        = "${local.environment}-backend-vpc"
  vpc_cidr        = "10.21.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.21.1.0/24", "10.21.2.0/24", "10.21.3.0/24"]
  public_subnets  = ["10.21.101.0/24", "10.21.102.0/24", "10.21.103.0/24"]

  single_nat_gateway = true
  cluster_name       = local.backend_cluster_name

  # TGW Connection & Routing Setup
  transit_gateway_id                         = data.aws_ec2_transit_gateway.this.id
  transit_gateway_route_table_association_id = data.aws_ec2_transit_gateway_route_table.spokes.id
  transit_gateway_route_table_propagation_id = data.aws_ec2_transit_gateway_route_table.inspection.id
  tgw_destinations                           = ["10.0.0.0/8"]

  tags = merge(local.tags, { Tier = "backend" })
}

# Staging Frontend EKS Cluster Module
module "frontend_eks" {
  source = "../../modules/eks"
  env    = local.environment

  cluster_name    = local.frontend_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.frontend_network.vpc_id
  subnet_ids      = module.frontend_network.private_subnets

  # Highly Available Node Groups for Staging Frontend
  eks_managed_node_groups = {
    frontend_nodes = {
      min_size     = 2
      max_size     = 6
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = local.environment
        Tier        = "frontend"
      }
    }
  }

  tags = merge(local.tags, { Tier = "frontend" })
}

# Staging Backend EKS Cluster Module
module "backend_eks" {
  source = "../../modules/eks"
  env    = local.environment

  cluster_name    = local.backend_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = module.backend_network.vpc_id
  subnet_ids      = module.backend_network.private_subnets

  # Highly Available Node Groups for Staging Backend
  eks_managed_node_groups = {
    backend_nodes = {
      min_size     = 2
      max_size     = 6
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = local.environment
        Tier        = "backend"
      }
    }
  }

  tags = merge(local.tags, { Tier = "backend" })
}

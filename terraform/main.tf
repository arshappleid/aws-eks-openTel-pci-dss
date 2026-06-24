locals {
  common_tags = {
    Project   = "aws-eks-openTel-pci-dss"
    ManagedBy = "Terraform"
  }
}


module "dev_network" {
  source = "./modules/network"
  env = "dev"

  vpc_name        = "dev-vpc"
  vpc_cidr        = "10.10.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  intra_subnets     = ["10.10.3.0/24"]

  single_nat_gateway = true
  cluster_name       = "dev-eks-cluster"

  tags = merge(local.common_tags, { Environment = "dev" })
}

module "dev_eks" {
  source = "./modules/eks"
  env = "dev"

  cluster_name    = "dev-eks-cluster"
  cluster_version = var.kubernetes_version
  vpc_id          = module.dev_network.vpc_id
  subnet_ids      = module.dev_network.private_subnets

  eks_managed_node_groups = {
    dev_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t2.micro"]
      capacity_type  = "SPOT"

      labels = {
        Environment = "dev"
      }
    }
  }

  tags = merge(local.common_tags, { Environment = "dev" })
}


module "stage_network" {
  source = "./modules/network"
  env = "stage"

  vpc_name        = "stage-vpc"
  vpc_cidr        = "10.20.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
  intra_subnets     = ["10.20.3.0/24"]

  single_nat_gateway = true
  cluster_name       = "stage-eks-cluster"

  tags = merge(local.common_tags, { Environment = "stage" })
}

module "stage_eks" {
  source = "./modules/eks"
  env = "stage"

  cluster_name    = "stage-eks-cluster"
  cluster_version = var.kubernetes_version
  vpc_id          = module.stage_network.vpc_id
  subnet_ids      = module.stage_network.private_subnets

  eks_managed_node_groups = {
    stage_nodes = {
      min_size     = 1
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"

      labels = {
        Environment = "stage"
      }
    }
  }

  tags = merge(local.common_tags, { Environment = "stage" })
}



module "prod_network" {
  source = "./modules/network"
  env = "prod"

  vpc_name        = "prod-vpc"
  vpc_cidr        = "10.30.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.30.1.0/24", "10.30.2.0/24"]
  intra_subnets     = ["10.30.3.0/24"]


  single_nat_gateway = false
  cluster_name       = "prod-eks-cluster"

  tags = merge(local.common_tags, { Environment = "prod" })
}

module "prod_eks" {
  source = "./modules/eks"
  env = "prod"

  cluster_name                   = "prod-eks-cluster"
  cluster_version                = var.kubernetes_version
  vpc_id                         = module.prod_network.vpc_id
  subnet_ids                     = module.prod_network.private_subnets
  cluster_endpoint_public_access = var.prod_cluster_endpoint_public_access

  eks_managed_node_groups = {
    prod_nodes = {
      min_size     = 2
      max_size     = 10
      desired_size = 3

      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"


      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        Environment = "prod"
      }
    }
  }

  tags = merge(local.common_tags, { Environment = "prod" })
}
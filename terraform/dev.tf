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
      capacity_type  = "SPOT" # Cost savings for Dev

      labels = {
        Environment = "dev"
      }
    }
  }

  tags = merge(local.common_tags, { Environment = "dev" })
}
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

# Frontend EKS Cluster Module

module "frontend_eks" {
  providers = {
    helm       = helm.frontend
    kubernetes = kubernetes.frontend
  }
  source = "../../../modules/eks"
  env    = local.environment

  cluster_name    = local.frontend_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = data.aws_vpc.frontend.id
  subnet_ids      = data.aws_subnets.frontend_private.ids

  # Highly Available Node Groups for Staging Frontend
  eks_managed_node_groups = {
    frontend_nodes = {
      min_size     = 2
      max_size     = 6
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

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
  providers = {
    helm       = helm.backend
    kubernetes = kubernetes.backend
  }
  source = "../../../modules/eks"
  env    = local.environment

  cluster_name    = local.backend_cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = data.aws_vpc.backend.id
  subnet_ids      = data.aws_subnets.backend_private.ids

  # Highly Available Node Groups for Staging Backend
  eks_managed_node_groups = {
    backend_nodes = {
      min_size     = 2
      max_size     = 6
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      labels = {
        Environment = local.environment
        Tier        = "backend"
      }
    }
  }

  tags = merge(local.tags, { Tier = "backend" })
}



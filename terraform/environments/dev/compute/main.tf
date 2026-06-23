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


data "aws_vpc" "frontend" {
  filter {
    name   = "tag:Name"
    values = ["${local.environment}-frontend-vpc"]
  }
}

data "aws_subnets" "frontend_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.frontend.id]
  }
  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

data "aws_vpc" "backend" {
  filter {
    name   = "tag:Name"
    values = ["${local.environment}-backend-vpc"]
  }
}

data "aws_subnets" "backend_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.backend.id]
  }
  tags = {
    "kubernetes.io/role/internal-elb" = "1"
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

  # Highly Available Node Groups for Frontend
  eks_managed_node_groups = {
    frontend_nodes = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT" # Cost savings for dev environment

      labels = {
        Environment = local.environment
        Tier        = "frontend"
      }
    }
  }

  tags = merge(local.tags, { Tier = "frontend" })

  access_entries = {
    github_actions = {
      principal_arn = var.github_actions_role_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

# Dev Backend EKS Cluster Module
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

  # Highly Available Node Groups for Backend
  eks_managed_node_groups = {
    backend_nodes = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT" # Cost savings for dev environment

      labels = {
        Environment = local.environment
        Tier        = "backend"
      }
    }
  }

  tags = merge(local.tags, { Tier = "backend" })

  access_entries = {
    github_actions = {
      principal_arn = var.github_actions_role_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

# Look up Target Groups from the Shared ALB
data "aws_lb_target_group" "frontend" {
  name = "tg-frontend-${local.environment}"
}

data "aws_lb_target_group" "backend" {
  name = "tg-backend-${local.environment}"
}

# Bind EKS Frontend Service to ALB Target Group
resource "kubernetes_manifest" "frontend_target_binding" {
  provider = kubernetes.frontend

  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "frontend-tg-binding"
      namespace = "default"
    }
    spec = {
      targetGroupARN = data.aws_lb_target_group.frontend.arn
      targetType     = "ip"
      serviceRef = {
        name = "financeguard-frontend-service"
        port = 80
      }
    }
  }

  depends_on = [module.frontend_eks]
}

# Bind EKS Backend Service to ALB Target Group
resource "kubernetes_manifest" "backend_target_binding" {
  provider = kubernetes.backend

  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "backend-tg-binding"
      namespace = "default"
    }
    spec = {
      targetGroupARN = data.aws_lb_target_group.backend.arn
      targetType     = "ip"
      serviceRef = {
        name = "financeguard-backend-service"
        port = 80
      }
    }
  }

  depends_on = [module.backend_eks]
}


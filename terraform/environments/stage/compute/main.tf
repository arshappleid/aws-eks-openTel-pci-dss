
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

  access_entries = {
    github_actions = {
      principal_arn = "arn:aws:iam::866934333672:role/GITHUB-ACTIONS-ALL-REPO"
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = merge(local.tags, { Tier = "frontend" })
}


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

  access_entries = {
    github_actions = {
      principal_arn = "arn:aws:iam::866934333672:role/GITHUB-ACTIONS-ALL-REPO"
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = merge(local.tags, { Tier = "backend" })
}


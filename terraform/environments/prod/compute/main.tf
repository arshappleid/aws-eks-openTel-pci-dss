
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


data "aws_vpc" "frontend" {
  filter {
    name   = "tag:Name"
    values = ["${local.environment}-frontend-vpc"]
  }
}

data "aws_iam_role" "bastion" {
  name = "bastion-server-role"
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



module "frontend_eks" {
  providers = {
    helm       = helm.frontend
    kubernetes = kubernetes.frontend
  }
  source = "../../../modules/eks"
  env    = local.environment

  cluster_name                   = local.frontend_cluster_name
  cluster_version                = var.kubernetes_version
  vpc_id                         = data.aws_vpc.frontend.id
  subnet_ids                     = data.aws_subnets.frontend_private.ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access


  eks_managed_node_groups = {
    frontend_nodes = {
      min_size     = 2
      max_size     = 10
      desired_size = 3

      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"


      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        Environment = local.environment
        Tier        = "frontend"
      }
    }
  }

  tags = merge(local.tags, { Tier = "frontend" })

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
    bastion = {
      principal_arn = data.aws_iam_role.bastion.arn
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
}


module "backend_eks" {
  providers = {
    helm       = helm.backend
    kubernetes = kubernetes.backend
  }
  source = "../../../modules/eks"
  env    = local.environment

  cluster_name                   = local.backend_cluster_name
  cluster_version                = var.kubernetes_version
  vpc_id                         = data.aws_vpc.backend.id
  subnet_ids                     = data.aws_subnets.backend_private.ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access


  eks_managed_node_groups = {
    backend_nodes = {
      min_size     = 2
      max_size     = 10
      desired_size = 3

      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"


      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        Environment = local.environment
        Tier        = "backend"
      }
    }
  }

  tags = merge(local.tags, { Tier = "backend" })

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
    bastion = {
      principal_arn = data.aws_iam_role.bastion.arn
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
}



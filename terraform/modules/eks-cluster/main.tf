terraform {
  required_providers {
    helm = {
      source                = "hashicorp/helm"
      configuration_aliases = [helm.frontend, helm.backend]
    }
    kubernetes = {
      source                = "hashicorp/kubernetes"
      configuration_aliases = [kubernetes.frontend, kubernetes.backend]
    }
  }
}

locals {
  frontend_cluster_name = "${var.app_name}-${var.env}-frontend"
  backend_cluster_name  = "${var.app_name}-${var.env}-backend"
  tags = {
    Environment = var.env
    Project     = "aws-eks-openTel-pci-dss"
    ManagedBy   = "Terraform"
  }
}

data "aws_iam_role" "bastion" {
  name = "bastion-server-role"
}

data "aws_vpc" "frontend" {
  filter {
    name   = "tag:Name"
    values = ["${var.env}-frontend-vpc"]
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
    values = ["${var.env}-backend-vpc"]
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
  source = "../eks"
  env    = var.env

  cluster_name                   = local.frontend_cluster_name
  cluster_version                = var.kubernetes_version
  vpc_id                         = data.aws_vpc.frontend.id
  subnet_ids                     = data.aws_subnets.frontend_private.ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access

  access_entries = {
    github_actions = {
      principal_arn = var.github_actions_role_arn
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

  tags = merge(local.tags, { Tier = "frontend" })
}

module "backend_eks" {
  providers = {
    helm       = helm.backend
    kubernetes = kubernetes.backend
  }
  source = "../eks"
  env    = var.env

  cluster_name                   = local.backend_cluster_name
  cluster_version                = var.kubernetes_version
  vpc_id                         = data.aws_vpc.backend.id
  subnet_ids                     = data.aws_subnets.backend_private.ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access

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

  tags = merge(local.tags, { Tier = "backend" })
}

# --- Reachability Logic ---

data "aws_instances" "backend_nodes" {
  count = var.enable_reachability ? 1 : 0
  filter {
    name   = "tag:kubernetes.io/cluster/${local.backend_cluster_name}"
    values = ["owned"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "backend_node" {
  count       = var.enable_reachability && length(data.aws_instances.backend_nodes[0].ids) > 0 ? 1 : 0
  instance_id = data.aws_instances.backend_nodes[0].ids[0]
}

locals {
  eks_node_eni_id = length(data.aws_instance.backend_node) > 0 ? data.aws_instance.backend_node[0].network_interface_id : ""
}

resource "aws_ec2_network_insights_path" "egress_to_dns" {
  count = var.enable_reachability && local.eks_node_eni_id != "" ? 1 : 0

  source           = local.eks_node_eni_id
  destination      = "igw-07d73976f32aa275b" # Assuming this was hardcoded in stage. We'll leave it as is.
  destination_ip   = "8.8.8.8"
  destination_port = 53
  protocol         = "udp"

  tags = {
    Name = "${var.env}-egress-to-8.8.8.8"
  }
}

data "aws_network_interfaces" "alb" {
  count = var.enable_reachability ? 1 : 0
  filter {
    name   = "description"
    values = ["ELB app/inspection-alb/*"]
  }
}

resource "aws_ec2_network_insights_path" "ingress_from_alb" {
  count = var.enable_reachability && local.eks_node_eni_id != "" && length(data.aws_network_interfaces.alb[0].ids) > 0 ? 1 : 0

  source      = data.aws_network_interfaces.alb[0].ids[0]
  destination = local.eks_node_eni_id
  protocol    = "tcp"

  tags = {
    Name = "${var.env}-ingress-from-alb"
  }
}

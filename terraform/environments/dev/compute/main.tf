provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { Owner = "Prabhmeet" }
  }
}

variable "aws_region" {}
variable "env" {}
variable "kubernetes_version" {}
variable "cluster_name" {}

module "eks_cluster" {
  source = "../../../modules/eks-cluster"

  env                            = var.env
  kubernetes_version             = var.kubernetes_version
  cluster_endpoint_public_access = true
  enable_reachability            = false

  providers = {
    helm.frontend       = helm.frontend
    kubernetes.frontend = kubernetes.frontend
    helm.backend        = helm.backend
    kubernetes.backend  = kubernetes.backend
  }
}

output "frontend_cluster_name" { value = module.eks_cluster.frontend_cluster_name }
output "backend_cluster_name" { value = module.eks_cluster.backend_cluster_name }
output "frontend_cluster_endpoint" { value = module.eks_cluster.frontend_cluster_endpoint }
output "backend_cluster_endpoint" { value = module.eks_cluster.backend_cluster_endpoint }

provider "kubernetes" {
  alias                  = "frontend"
  host                   = module.eks_cluster.frontend_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.frontend_cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.frontend_cluster_name]
  }
}
provider "helm" {
  alias = "frontend"
  kubernetes {
    host                   = module.eks_cluster.frontend_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.frontend_cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.frontend_cluster_name]
    }
  }
}

provider "kubernetes" {
  alias                  = "backend"
  host                   = module.eks_cluster.backend_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.backend_cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.backend_cluster_name]
  }
}
provider "helm" {
  alias = "backend"
  kubernetes {
    host                   = module.eks_cluster.backend_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.backend_cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.backend_cluster_name]
    }
  }
}

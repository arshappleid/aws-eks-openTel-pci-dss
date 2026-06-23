# Provider configurations
# Version constraints are managed centrally in versions.tf (symlinked)

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner = "Prabhmeet"
    }
  }
}

# Default providers (un-aliased) required by Terraform for module initialization
provider "kubernetes" {
  host                   = module.frontend_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.frontend_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.frontend_eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.frontend_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.frontend_eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.frontend_eks.cluster_name]
    }
  }
}

# Frontend aliased providers
provider "kubernetes" {
  alias                  = "frontend"
  host                   = module.frontend_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.frontend_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.frontend_eks.cluster_name]
  }
}

provider "helm" {
  alias = "frontend"
  kubernetes {
    host                   = module.frontend_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.frontend_eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.frontend_eks.cluster_name]
    }
  }
}

# Backend aliased providers
provider "kubernetes" {
  alias                  = "backend"
  host                   = module.backend_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.backend_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.backend_eks.cluster_name]
  }
}

provider "helm" {
  alias = "backend"
  kubernetes {
    host                   = module.backend_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.backend_eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.backend_eks.cluster_name]
    }
  }
}

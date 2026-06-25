provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Owner = "Prabhmeet"
    }
  }
}


data "aws_eks_cluster" "frontend" {
  name = "financeguard-stage-frontend"
}

data "aws_eks_cluster_auth" "frontend" {
  name = "financeguard-stage-frontend"
}

data "aws_eks_cluster" "backend" {
  name = "financeguard-stage-backend"
}

data "aws_eks_cluster_auth" "backend" {
  name = "financeguard-stage-backend"
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.frontend.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.frontend.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.frontend.name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.frontend.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.frontend.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.frontend.name, "--region", var.aws_region]
    }
  }
}


provider "kubernetes" {
  alias                  = "frontend"
  host                   = data.aws_eks_cluster.frontend.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.frontend.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.frontend.name, "--region", var.aws_region]
  }
}

provider "helm" {
  alias                  = "frontend"
  kubernetes {
    host                   = data.aws_eks_cluster.frontend.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.frontend.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.frontend.name, "--region", var.aws_region]
    }
  }
}


provider "kubernetes" {
  alias                  = "backend"
  host                   = data.aws_eks_cluster.backend.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.backend.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.backend.name, "--region", var.aws_region]
  }
}

provider "helm" {
  alias                  = "backend"
  kubernetes {
    host                   = data.aws_eks_cluster.backend.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.backend.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.backend.name, "--region", var.aws_region]
    }
  }
}
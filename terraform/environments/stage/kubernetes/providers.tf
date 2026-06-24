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
  token                  = data.aws_eks_cluster_auth.frontend.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.frontend.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.frontend.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.frontend.token
  }
}


provider "kubernetes" {
  alias                  = "frontend"
  host                   = data.aws_eks_cluster.frontend.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.frontend.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.frontend.token
}

provider "helm" {
  alias                  = "frontend"
  kubernetes {
    host                   = data.aws_eks_cluster.frontend.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.frontend.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.frontend.token
  }
}


provider "kubernetes" {
  alias                  = "backend"
  host                   = data.aws_eks_cluster.backend.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.backend.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.backend.token
}

provider "helm" {
  alias                  = "backend"
  kubernetes {
    host                   = data.aws_eks_cluster.backend.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.backend.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.backend.token
  }
}
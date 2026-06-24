locals {
  environment = "dev"
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
}

# ArgoCD for Frontend
resource "helm_release" "frontend_argocd" {
  provider         = helm.frontend
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  set {
    name  = "configs.repositories.financeguard.url"
    value = "https://github.com/arshappleid/aws-eks-openTel-pci-dss"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "500m"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "server.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "server.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "server.resources.limits.cpu"
    value = "300m"
  }
  set {
    name  = "server.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "repoServer.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "repoServer.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "repoServer.resources.limits.cpu"
    value = "300m"
  }
  set {
    name  = "repoServer.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "redis.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "redis.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "redis.resources.limits.cpu"
    value = "300m"
  }
  set {
    name  = "redis.resources.limits.memory"
    value = "128Mi"
  }
}

# AWS Load Balancer Controller for Frontend
resource "helm_release" "frontend_aws_lbc" {
  provider   = helm.frontend
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.frontend.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = data.aws_eks_cluster.frontend.vpc_config[0].vpc_id
  }
}

# ArgoCD for Backend
resource "helm_release" "backend_argocd" {
  provider         = helm.backend
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  set {
    name  = "configs.repositories.financeguard.url"
    value = "https://github.com/arshappleid/aws-eks-openTel-pci-dss"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "500m"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "server.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "server.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "server.resources.limits.cpu"
    value = "300m"
  }
  set {
    name  = "server.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "repoServer.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "repoServer.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "repoServer.resources.limits.cpu"
    value = "300m"
  }
  set {
    name  = "repoServer.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "redis.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "redis.resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "redis.resources.limits.cpu"
    value = "300m"
  }
  set {
    name  = "redis.resources.limits.memory"
    value = "128Mi"
  }
}

# AWS Load Balancer Controller for Backend
resource "helm_release" "backend_aws_lbc" {
  provider   = helm.backend
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.backend.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = data.aws_eks_cluster.backend.vpc_config[0].vpc_id
  }
}

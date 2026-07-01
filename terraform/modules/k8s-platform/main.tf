locals {
  environment = "dev"
}


resource "kubernetes_manifest" "frontend_target_binding" {
  provider = kubernetes.frontend

  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "frontend-tg-binding"
      namespace = "react"
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

  depends_on = [kubernetes_namespace.react, helm_release.frontend_aws_lbc]
}


resource "kubernetes_manifest" "backend_target_binding" {
  provider = kubernetes.backend

  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "backend-tg-binding"
      namespace = "fastapi"
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

  depends_on = [kubernetes_namespace.fastapi, helm_release.backend_aws_lbc]
}

resource "kubernetes_manifest" "argocd_target_binding" {
  provider = kubernetes.frontend

  manifest = {
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "argocd-tg-binding"
      namespace = "argocd"
    }
    spec = {
      targetGroupARN = data.aws_lb_target_group.argocd.arn
      targetType     = "ip"
      serviceRef = {
        name = "argocd-server"
        port = 80
      }
    }
  }

  depends_on = [helm_release.frontend_argocd, helm_release.frontend_aws_lbc]
}



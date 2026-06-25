resource "kubernetes_namespace" "react" {
  provider = kubernetes.frontend
  metadata {
    name = "react"
  }
}

resource "kubernetes_namespace" "fastapi" {
  provider = kubernetes.backend
  metadata {
    name = "fastapi"
  }
}
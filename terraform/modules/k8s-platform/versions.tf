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

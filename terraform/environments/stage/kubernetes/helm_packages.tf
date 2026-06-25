resource "random_password" "argocd_webhook_secret_frontend" {
  length  = 32
  special = false
}

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
    name  = "configs.secret.githubSecret"
    value = random_password.argocd_webhook_secret_frontend.result
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
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
  set {
    name  = "server.extraArgs[1]"
    value = "--rootpath=/argocd"
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


resource "random_password" "argocd_webhook_secret_backend" {
  length  = 32
  special = false
}

resource "helm_release" "backend_argocd" {
  provider         = helm.backend
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  cleanup_on_fail  = true
  replace          = true
  force_update     = true

  set {
    name  = "configs.repositories.financeguard.url"
    value = "https://github.com/arshappleid/aws-eks-openTel-pci-dss"
  }

  set {
    name  = "configs.secret.githubSecret"
    value = random_password.argocd_webhook_secret_backend.result
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

  cleanup_on_fail  = true
  replace          = true
  force_update     = true

  set {
    name  = "vpcId"
    value = data.aws_eks_cluster.backend.vpc_config[0].vpc_id
  }
}

output "argocd_webhook_secret_frontend" {
  value     = random_password.argocd_webhook_secret_frontend.result
  sensitive = true
}

output "argocd_webhook_secret_backend" {
  value     = random_password.argocd_webhook_secret_backend.result
  sensitive = true
}


resource "helm_release" "frontend_otel_collector" {
  provider         = helm.frontend
  name             = "otel-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "kube-system"
  version          = "0.91.0"
  create_namespace = false

  values = [
    <<-EOT
    mode: daemonset
    image:
      repository: "otel/opentelemetry-collector-contrib"
    presets:
      kubernetesAttributes:
        enabled: true
      kubeletMetrics:
        enabled: true
      logsCollection:
        enabled: true
    config:
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318
      exporters:
        otlp/jaeger:
          endpoint: "otel-collector.financeguard.local:4317"
          tls:
            insecure: true
        prometheusremotewrite:
          endpoint: "http://otel-collector.financeguard.local/prometheus/api/v1/write"
          tls:
            insecure: true
        loki:
          endpoint: "http://otel-collector.financeguard.local/loki/api/v1/push"
      service:
        pipelines:
          traces:
            receivers: [otlp]
            processors: [memory_limiter, batch]
            exporters: [otlp/jaeger]
          metrics:
            receivers: [otlp, kubeletstats]
            processors: [memory_limiter, batch]
            exporters: [prometheusremotewrite]
          logs:
            receivers: [otlp, filelog]
            processors: [memory_limiter, batch]
            exporters: [loki]
    EOT
  ]
}


resource "helm_release" "backend_otel_collector" {
  provider         = helm.backend
  name             = "otel-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "kube-system"
  version          = "0.91.0"
  create_namespace = false

  values = [
    <<-EOT
    mode: daemonset
    image:
      repository: "otel/opentelemetry-collector-contrib"
    presets:
      kubernetesAttributes:
        enabled: true
      kubeletMetrics:
        enabled: true
      logsCollection:
        enabled: true
    config:
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318
      exporters:
        otlp/jaeger:
          endpoint: "otel-collector.financeguard.local:4317"
          tls:
            insecure: true
        prometheusremotewrite:
          endpoint: "http://otel-collector.financeguard.local/prometheus/api/v1/write"
          tls:
            insecure: true
        loki:
          endpoint: "http://otel-collector.financeguard.local/loki/api/v1/push"
      service:
        pipelines:
          traces:
            receivers: [otlp]
            processors: [memory_limiter, batch]
            exporters: [otlp/jaeger]
          metrics:
            receivers: [otlp, kubeletstats]
            processors: [memory_limiter, batch]
            exporters: [prometheusremotewrite]
          logs:
            receivers: [otlp, filelog]
            processors: [memory_limiter, batch]
            exporters: [loki]
    EOT
  ]
}


resource "helm_release" "frontend_fluent_bit" {
  provider   = helm.frontend
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "kube-system"
  version    = "0.47.0"

  cleanup_on_fail  = true
  replace          = true
  force_update     = true

  values = [
    <<-EOT
    config:
      service: |
        [SERVICE]
            Flush         1
            Log_Level     info
            Daemon        off
            HTTP_Server   On
            HTTP_Listen   0.0.0.0
            HTTP_Port     2020

      inputs: |
        [INPUT]
            Name              tail
            Tag               kube.*
            Path              /var/log/containers/*.log

      outputs: |
        [OUTPUT]
            Name              forward
            Match             *
            Host              otel-collector.financeguard.local
            Port              24224
    EOT
  ]
}

resource "helm_release" "backend_fluent_bit" {
  provider   = helm.backend
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "kube-system"
  version    = "0.47.0"

  cleanup_on_fail  = true
  replace          = true
  force_update     = true

  values = [
    <<-EOT
    config:
      service: |
        [SERVICE]
            Flush         1
            Log_Level     info
            Daemon        off
            HTTP_Server   On
            HTTP_Listen   0.0.0.0
            HTTP_Port     2020

      inputs: |
        [INPUT]
            Name              tail
            Tag               kube.*
            Path              /var/log/containers/*.log

      outputs: |
        [OUTPUT]
            Name              forward
            Match             *
            Host              otel-collector.financeguard.local
            Port              24224
    EOT
  ]
}
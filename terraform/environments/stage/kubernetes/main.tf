locals {
  environment = "stage"
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

# OpenTelemetry Collector for Frontend EKS (Stage)
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

# OpenTelemetry Collector for Backend EKS (Stage)
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

# Fluent Bit for Frontend EKS
resource "helm_release" "frontend_fluent_bit" {
  provider   = helm.frontend
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "kube-system"
  version    = "0.47.0"

  values = [
    <<-EOT
    config:
      service: |
        [SERVICE]
            Flush         1
            Log_Level     info
            Daemon        off
            Parsers_File  parsers.conf

      inputs: |
        [INPUT]
            Name              tail
            Tag               kube.*
            Path              /var/log/containers/*.log
            Parser            docker
            DB                /var/log/flb_kube.db
            Mem_Buf_Limit     50MB
            Skip_Long_Lines   On

      filters: |
        [FILTER]
            Name                kubernetes
            Match               kube.*
            Kube_URL            https://kubernetes.default.svc:443
            Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
            Kube_Tag_Prefix     kube.var.log.containers.
            Merge_Log           On
            Keep_Log            Off
            K8S-Logging.Parser  On
            K8S-Logging.Exclude On

      outputs: |
        [OUTPUT]
            Name            opensearch
            Match           *
            Host            otel-collector.financeguard.local
            Port            80
            Path            /opensearch
            Index           financeguard-stage-frontend-logs
            Type            _doc
            TLS             Off
            Suppress_Type   On

        [OUTPUT]
            Name            syslog
            Match           *
            Host            otel-collector.financeguard.local
            Port            514
            Mode            udp
            Syslog_Format   rfc5424
            Syslog_Severity_Key  level
            Syslog_Facility_Key  facility
    EOT
  ]
}

# Fluent Bit for Backend EKS
resource "helm_release" "backend_fluent_bit" {
  provider   = helm.backend
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "kube-system"
  version    = "0.47.0"

  values = [
    <<-EOT
    config:
      service: |
        [SERVICE]
            Flush         1
            Log_Level     info
            Daemon        off
            Parsers_File  parsers.conf

      inputs: |
        [INPUT]
            Name              tail
            Tag               kube.*
            Path              /var/log/containers/*.log
            Parser            docker
            DB                /var/log/flb_kube.db
            Mem_Buf_Limit     50MB
            Skip_Long_Lines   On

      filters: |
        [FILTER]
            Name                kubernetes
            Match               kube.*
            Kube_URL            https://kubernetes.default.svc:443
            Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
            Kube_Tag_Prefix     kube.var.log.containers.
            Merge_Log           On
            Keep_Log            Off
            K8S-Logging.Parser  On
            K8S-Logging.Exclude On

      outputs: |
        [OUTPUT]
            Name            opensearch
            Match           *
            Host            otel-collector.financeguard.local
            Port            80
            Path            /opensearch
            Index           financeguard-stage-backend-logs
            Type            _doc
            TLS             Off
            Suppress_Type   On

        [OUTPUT]
            Name            syslog
            Match           *
            Host            otel-collector.financeguard.local
            Port            514
            Mode            udp
            Syslog_Format   rfc5424
            Syslog_Severity_Key  level
            Syslog_Facility_Key  facility
    EOT
  ]
}

# EKS Access Entries moved from Compute Layer to Kubernetes Layer
resource "aws_eks_access_entry" "github_actions_frontend" {
  cluster_name  = data.aws_eks_cluster.frontend.name
  principal_arn = var.github_actions_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_frontend" {
  cluster_name  = data.aws_eks_cluster.frontend.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.github_actions_role_arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "github_actions_backend" {
  cluster_name  = data.aws_eks_cluster.backend.name
  principal_arn = var.github_actions_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_backend" {
  cluster_name  = data.aws_eks_cluster.backend.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.github_actions_role_arn

  access_scope {
    type = "cluster"
  }
}



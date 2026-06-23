# Custom EKS module wrapping Anton Babenko's EKS module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  create_cloudwatch_log_group = false

  name    = var.cluster_name
  kubernetes_version = var.cluster_version

  # Enable cluster endpoint public access for administration, but keep private access enabled
  endpoint_public_access   = var.cluster_endpoint_public_access
  enable_cluster_creator_admin_permissions  = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Prevent AWS IAM name_prefix length limit errors (max 38 chars) for long cluster names
  node_iam_role_use_name_prefix = false

  # EKS Auto Mode Compute Configuration
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  access_entries = var.access_entries

  tags = var.tags
}

# Explicitly add an allow-all outbound rule to the Cluster Security Group
# since the module argument was unsupported in your current setup.
resource "aws_security_group_rule" "cluster_egress_all" {
  description       = "Allow all outbound traffic from the EKS cluster control plane"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.cluster_security_group_id
}

# Allow ingress from the Inspection VPC (containing the central ALB) to EKS worker nodes
resource "aws_security_group_rule" "node_ingress_inspection" {
  description       = "Allow inbound TCP traffic from Inspection VPC CIDR"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = module.eks.node_security_group_id
}

# Allow ingress from the Inspection VPC (containing the central ALB) to EKS control plane/cluster security group
resource "aws_security_group_rule" "cluster_ingress_inspection" {
  description       = "Allow inbound TCP traffic from Inspection VPC CIDR to cluster security group"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = module.eks.cluster_security_group_id
}

# Automatically deploy ArgoCD into every cluster provisioned by this module
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  # Register the GitHub repository in ArgoCD automatically
  set {
    name  = "configs.repositories.financeguard.url"
    value = var.github_repo_url
  }

  # Restrict resource footprints to avoid namespace quota exhaustion
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

  # Wait for EKS cluster and networking to be fully ready
  depends_on = [module.eks, aws_security_group_rule.cluster_egress_all]
}

# Fetch the official AWS Load Balancer Controller IAM Policy JSON
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# Create IAM Policy for Load Balancer Controller
resource "aws_iam_policy" "lbc" {
  name        = "${var.cluster_name}-aws-lbc-policy"
  description = "IAM policy for AWS Load Balancer Controller in EKS cluster ${var.cluster_name}"
  policy      = data.http.lbc_iam_policy.response_body
}

# Create IAM Role for Load Balancer Controller with Pod Identity Trust Policy
resource "aws_iam_role" "lbc" {
  name = "${var.cluster_name}-aws-lbc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "lbc" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = aws_iam_role.lbc.name
}

# Create EKS Pod Identity Association for Load Balancer Controller
resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lbc.arn

  depends_on = [module.eks]
}

# Deploy self-managed AWS Load Balancer Controller via Helm
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = var.cluster_name
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
    value = var.vpc_id
  }

  # Ensure Pod Identity and core cluster are fully active before running Helm install
  depends_on = [module.eks, aws_eks_pod_identity_association.lbc]
}


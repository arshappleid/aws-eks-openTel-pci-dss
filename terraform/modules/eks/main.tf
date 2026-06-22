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

  # Wait for EKS cluster and networking to be fully ready
  depends_on = [module.eks, aws_security_group_rule.cluster_egress_all]
}

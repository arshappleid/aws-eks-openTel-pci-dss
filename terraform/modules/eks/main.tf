
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  create_cloudwatch_log_group = false

  name    = var.cluster_name
  kubernetes_version = var.cluster_version


  enabled_log_types = ["audit", "api", "authenticator", "controllerManager", "scheduler"]


  endpoint_public_access   = var.cluster_endpoint_public_access
  enable_cluster_creator_admin_permissions  = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids


  node_iam_role_use_name_prefix = false


  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  access_entries = var.access_entries

  tags = var.tags
}



resource "aws_security_group_rule" "cluster_egress_all" {
  description       = "Allow all outbound traffic from the EKS cluster control plane"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.cluster_security_group_id
}


resource "aws_security_group_rule" "node_ingress_inspection" {
  description       = "Allow inbound TCP traffic from Inspection VPC CIDR"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["192.178.0.0/16"]
  security_group_id = module.eks.cluster_primary_security_group_id
}


resource "aws_security_group_rule" "node_ssh_ingress" {
  description       = "Allow inbound SSH from Inspection VPC CIDR to worker nodes"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["192.178.0.0/16"]
  security_group_id = module.eks.node_security_group_id
}


resource "aws_security_group_rule" "node_ssh_ingress_primary" {
  description       = "Allow inbound SSH from Inspection VPC CIDR to EKS primary security group"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["192.178.0.0/16"]
  security_group_id = module.eks.cluster_primary_security_group_id
}




resource "aws_security_group_rule" "cluster_ingress_inspection" {
  description       = "Allow inbound TCP traffic from Inspection VPC CIDR to cluster security group"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["192.178.0.0/16"]
  security_group_id = module.eks.cluster_security_group_id
}



data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}


resource "aws_iam_policy" "lbc" {
  name        = "${var.cluster_name}-aws-lbc-policy"
  description = "IAM policy for AWS Load Balancer Controller in EKS cluster ${var.cluster_name}"
  policy      = data.http.lbc_iam_policy.response_body
}


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


resource "aws_iam_role_policy_attachment" "lbc" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = aws_iam_role.lbc.name
}


resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lbc.arn

  depends_on = [module.eks]
}


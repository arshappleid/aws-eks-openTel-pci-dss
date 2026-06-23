variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the Prod EKS cluster"
  type        = string
  default     = "prod-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "1.36"
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions"
  type        = string
  default     = "arn:aws:iam::866934333672:role/GITHUB-ACTIONS-ALL-REPO"
}
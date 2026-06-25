variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the Dev EKS cluster"
  type        = string
  default     = "dev-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "1.31"
}
variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
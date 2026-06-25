variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the Staging EKS cluster"
  type        = string
  default     = "stage-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "1.31"
}
variable "env" {
  description = "Environment name"
  type        = string
  default     = "stage"
}
variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the clusters"
  type        = string
  default     = "1.30"
}

variable "prod_cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled for Production"
  type        = bool
  default     = true
}
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster nodes will be spawned (typically private subnets)"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
variable "env" {
  description = "Environment name"
  type        = string
}

variable "github_repo_url" {
  description = "The GitHub repository URL for ArgoCD to pull configurations from"
  type        = string
  default     = "https://github.com/arshappleid/aws-eks-openTel-pci-dss"
}
variable "env" {
  type        = string
  description = "Environment name"
}

variable "app_name" {
  type        = string
  default     = "financeguard"
  description = "Application name"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to use"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
}

variable "enable_reachability" {
  type        = bool
  default     = false
  description = "Enable reachability test"
}

variable "github_actions_role_arn" {
  type        = string
  default     = "arn:aws:iam::866934333672:role/GITHUB-ACTIONS-ALL-REPO"
  description = "ARN of the IAM role assumed by GitHub Actions"
}

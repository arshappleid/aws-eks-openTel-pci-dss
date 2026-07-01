variable "env" {
  type        = string
  description = "Environment name"
}

variable "app_name" {
  type        = string
  default     = "financeguard"
  description = "Application name"
}

variable "github_repo_url" {
  type        = string
  default     = "https://github.com/arshappleid/aws-eks-openTel-pci-dss"
}

# Helm Chart Versions
variable "argocd_version" {
  type    = string
  default = "5.46.7"
}

variable "aws_lbc_version" {
  type    = string
  default = "1.8.1"
}

variable "otel_collector_version" {
  type    = string
  default = "0.91.0"
}

variable "fluent_bit_version" {
  type    = string
  default = "0.47.0"
}

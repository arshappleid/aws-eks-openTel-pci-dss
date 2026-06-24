variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions"
  type        = string
  default     = "arn:aws:iam::866934333672:role/GITHUB-ACTIONS-ALL-REPO"
}
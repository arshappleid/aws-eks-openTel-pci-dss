variable "aws_region" {
  description = "The AWS region to deploy shared resources into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the Inspection VPC"
  type        = string
  default     = "192.178.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks for the Inspection VPC"
  type        = list(string)
  default     = ["192.178.101.0/24", "192.178.102.0/24", "192.178.103.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks for the Inspection VPC (firewall/TGW endpoints)"
  type        = list(string)
  default     = ["192.178.1.0/24", "192.178.2.0/24", "192.178.3.0/24"]
}

variable "common_tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "financeguard"
    ManagedBy   = "Terraform"
    Owner = "Prabmeet"
  }
}

variable "services" {
  description = "Map of frontend services to route via ALB path-based routing"
  type = map(object({
    path_pattern       = string
    health_check_path  = string
    alb_route_priority = number
    strip_path_prefix  = bool
  }))
  default = {
    backend-dev = {
      path_pattern       = "/dev/api/*"
      health_check_path  = "/health"
      alb_route_priority = 10
      strip_path_prefix  = true
    }
    backend-stage = {
      path_pattern       = "/stage/api/*"
      health_check_path  = "/health"
      alb_route_priority = 20
      strip_path_prefix  = true
    }
    backend-prod = {
      path_pattern       = "/prod/api/*"
      health_check_path  = "/health"
      alb_route_priority = 30
      strip_path_prefix  = true
    }
    frontend-dev = {
      path_pattern       = "/dev/*"
      health_check_path  = "/"
      alb_route_priority = 100
      strip_path_prefix  = true
    }
    frontend-stage = {
      path_pattern       = "/stage/*"
      health_check_path  = "/"
      alb_route_priority = 110
      strip_path_prefix  = true
    }
    frontend-stage-argocd = {
      path_pattern       = "/argocd/*"
      health_check_path  = "/argocd/healthz"
      alb_route_priority = 115
      strip_path_prefix  = false
    }
    frontend-prod = {
      path_pattern       = "/prod/*"
      health_check_path  = "/"
      alb_route_priority = 120
      strip_path_prefix  = true
    }
  }
}
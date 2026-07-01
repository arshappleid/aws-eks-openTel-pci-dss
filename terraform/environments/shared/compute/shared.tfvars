# shared/compute — variable values for the shared workspace
aws_region      = "us-east-1"
vpc_cidr        = "192.178.0.0/16"
public_subnets  = ["192.178.101.0/24", "192.178.102.0/24", "192.178.103.0/24"]
private_subnets = ["192.178.1.0/24", "192.178.2.0/24", "192.178.3.0/24"]

common_tags = {
  Environment = "shared"
  Project     = "financeguard"
  ManagedBy   = "Terraform"
  Owner       = "Prabhmeet"
}

services = {
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
    health_check_path  = "/healthz"
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

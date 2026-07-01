variable "services" {
  description = "Map of frontend services to route via ALB path-based routing"
  type = map(object({
    path_pattern       = string
    health_check_path  = string
    alb_route_priority = number
    strip_path_prefix  = bool
  }))
}

locals {
  common_tags = {
    Project     = "financeguard"
    ManagedBy   = "Terraform"
    Environment = "shared"
    Owner       = "Prabmeet"
  }
}

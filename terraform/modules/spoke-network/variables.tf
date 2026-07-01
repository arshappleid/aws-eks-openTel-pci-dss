variable "env" {
  type        = string
  description = "Environment name"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "app_name" {
  type        = string
  default     = "financeguard"
  description = "Application name"
}

variable "frontend_vpc_cidr" {
  type        = string
  description = "CIDR for frontend VPC"
}

variable "frontend_private_subnets" {
  type        = list(string)
  description = "Private subnets for frontend VPC"
}

variable "frontend_intra_subnets" {
  type        = list(string)
  description = "Intra subnets for frontend VPC"
}

variable "backend_vpc_cidr" {
  type        = string
  description = "CIDR for backend VPC"
}

variable "backend_private_subnets" {
  type        = list(string)
  description = "Private subnets for backend VPC"
}

variable "backend_intra_subnets" {
  type        = list(string)
  description = "Intra subnets for backend VPC"
}

variable "tgw_destinations" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Destinations for TGW routes"
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "Use single NAT gateway"
}

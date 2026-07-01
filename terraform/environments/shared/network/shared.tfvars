# shared/network — variable values for the shared workspace
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

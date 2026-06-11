# ==============================================================================
# INSPECTION VPC & TRANSIT GATEWAY OUTPUTS (from Shared Module)
# ==============================================================================
output "inspection_vpc_id" {
  description = "The ID of the Inspection VPC"
  value       = module.shared.inspection_vpc_id
}

output "inspection_vpc_cidr_block" {
  description = "The CIDR block of the Inspection VPC"
  value       = module.shared.inspection_vpc_cidr_block
}

output "inspection_private_subnets" {
  description = "List of IDs of Inspection VPC private subnets (firewall endpoints)"
  value       = module.shared.inspection_private_subnets
}

output "inspection_public_subnets" {
  description = "List of IDs of Inspection VPC public subnets"
  value       = module.shared.inspection_public_subnets
}

output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = module.shared.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = module.shared.transit_gateway_arn
}

output "transit_gateway_spoke_route_table_id" {
  description = "The ID of the TGW Spoke Route Table"
  value       = module.shared.transit_gateway_spoke_route_table_id
}

output "transit_gateway_inspection_route_table_id" {
  description = "The ID of the TGW Inspection Route Table"
  value       = module.shared.transit_gateway_inspection_route_table_id
}

# ==============================================================================
# PROD ENVIRONMENT OUTPUTS
# ==============================================================================
output "prod_frontend_vpc_id" {
  description = "The ID of the Prod Frontend VPC"
  value       = module.prod.frontend_vpc_id
}

output "prod_backend_vpc_id" {
  description = "The ID of the Prod Backend VPC"
  value       = module.prod.backend_vpc_id
}

output "prod_frontend_cluster_name" {
  description = "The name of the Prod Frontend EKS Cluster"
  value       = module.prod.frontend_cluster_name
}

output "prod_frontend_cluster_endpoint" {
  description = "The endpoint of the Prod Frontend EKS Cluster"
  value       = module.prod.frontend_cluster_endpoint
}

output "prod_backend_cluster_name" {
  description = "The name of the Prod Backend EKS Cluster"
  value       = module.prod.backend_cluster_name
}

output "prod_backend_cluster_endpoint" {
  description = "The endpoint of the Prod Backend EKS Cluster"
  value       = module.prod.backend_cluster_endpoint
}

# ==============================================================================
# STAGE ENVIRONMENT OUTPUTS
# ==============================================================================
output "stage_frontend_vpc_id" {
  description = "The ID of the Stage Frontend VPC"
  value       = module.stage.frontend_vpc_id
}

output "stage_backend_vpc_id" {
  description = "The ID of the Stage Backend VPC"
  value       = module.stage.backend_vpc_id
}

output "stage_frontend_cluster_name" {
  description = "The name of the Stage Frontend EKS Cluster"
  value       = module.stage.frontend_cluster_name
}

output "stage_frontend_cluster_endpoint" {
  description = "The endpoint of the Stage Frontend EKS Cluster"
  value       = module.stage.frontend_cluster_endpoint
}

output "stage_backend_cluster_name" {
  description = "The name of the Stage Backend EKS Cluster"
  value       = module.stage.backend_cluster_name
}

output "stage_backend_cluster_endpoint" {
  description = "The endpoint of the Stage Backend EKS Cluster"
  value       = module.stage.backend_cluster_endpoint
}

# ==============================================================================
# DEV ENVIRONMENT OUTPUTS
# ==============================================================================
output "dev_frontend_vpc_id" {
  description = "The ID of the Dev Frontend VPC"
  value       = module.dev.frontend_vpc_id
}

output "dev_backend_vpc_id" {
  description = "The ID of the Dev Backend VPC"
  value       = module.dev.backend_vpc_id
}

output "dev_frontend_cluster_name" {
  description = "The name of the Dev Frontend EKS Cluster"
  value       = module.dev.frontend_cluster_name
}

output "dev_frontend_cluster_endpoint" {
  description = "The endpoint of the Dev Frontend EKS Cluster"
  value       = module.dev.frontend_cluster_endpoint
}

output "dev_backend_cluster_name" {
  description = "The name of the Dev Backend EKS Cluster"
  value       = module.dev.backend_cluster_name
}

output "dev_backend_cluster_endpoint" {
  description = "The endpoint of the Dev Backend EKS Cluster"
  value       = module.dev.backend_cluster_endpoint
}

output "frontend_vpc_id" {
  description = "The ID of the Frontend VPC"
  value       = module.frontend_network.vpc_id
}

output "frontend_private_subnets" {
  description = "Private subnets for Frontend VPC"
  value       = module.frontend_network.private_subnets
}

output "frontend_public_subnets" {
  description = "Public subnets for Frontend VPC"
  value       = module.frontend_network.public_subnets
}

output "backend_vpc_id" {
  description = "The ID of the Backend VPC"
  value       = module.backend_network.vpc_id
}

output "backend_private_subnets" {
  description = "Private subnets for Backend VPC"
  value       = module.backend_network.private_subnets
}

output "backend_public_subnets" {
  description = "Public subnets for Backend VPC"
  value       = module.backend_network.public_subnets
}

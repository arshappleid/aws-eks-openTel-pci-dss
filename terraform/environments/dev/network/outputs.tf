output "frontend_vpc_id" {
  description = "The ID of the Dev Frontend VPC"
  value       = module.frontend_network.vpc_id
}

output "backend_vpc_id" {
  description = "The ID of the Dev Backend VPC"
  value       = module.backend_network.vpc_id
}
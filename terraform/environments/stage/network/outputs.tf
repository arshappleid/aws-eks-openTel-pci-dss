output "frontend_vpc_id" {
  description = "The ID of the Staging Frontend VPC"
  value       = module.frontend_network.vpc_id
}
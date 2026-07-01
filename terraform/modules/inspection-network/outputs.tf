output "vpc_id" {
  value = module.inspection_vpc.vpc_id
}
output "private_subnets" {
  value = module.inspection_vpc.private_subnets
}
output "public_subnets" {
  value = module.inspection_vpc.public_subnets
}
output "service_discovery_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.internal.id
}
output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.this.id
}

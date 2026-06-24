output "inspection_vpc_id" {
  description = "The ID of the Inspection VPC"
  value       = module.inspection_vpc.vpc_id
}

output "inspection_vpc_cidr_block" {
  description = "The CIDR block of the Inspection VPC"
  value       = module.inspection_vpc.vpc_cidr_block
}

output "inspection_private_subnets" {
  description = "List of IDs of Inspection VPC private subnets"
  value       = module.inspection_vpc.private_subnets
}

output "inspection_public_subnets" {
  description = "List of IDs of Inspection VPC public subnets"
  value       = module.inspection_vpc.public_subnets
}

output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "The ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.arn
}

output "transit_gateway_spoke_route_table_id" {
  description = "The ID of the TGW Spoke Route Table"
  value       = aws_ec2_transit_gateway_route_table.spokes.id
}

output "transit_gateway_inspection_route_table_id" {
  description = "The ID of the TGW Inspection Route Table"
  value       = aws_ec2_transit_gateway_route_table.inspection.id
}

output "alb_dns_name" {
  description = "The public DNS name of the ALB"
  value       = module.alb.dns_name
}

output "bastion_public_ip" {
  description = "The public IP of the Bastion server"
  value       = aws_eip.bastion.public_ip
}

output "bastion_instance_id" {
  description = "The instance ID of the Bastion server"
  value       = aws_instance.bastion.id
}


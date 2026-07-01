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

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { Owner = "Prabmeet" }
  }
}

variable "aws_region" {}
variable "services" {
  type = map(object({
    path_pattern       = string
    health_check_path  = string
    alb_route_priority = number
    strip_path_prefix  = bool
  }))
}

module "shared_compute" {
  source   = "../../../modules/shared-compute"
  services = var.services
}

output "alb_dns_name" { value = module.shared_compute.alb_dns_name }
output "bastion_public_ip" { value = module.shared_compute.bastion_public_ip }
output "bastion_instance_id" { value = module.shared_compute.bastion_instance_id }

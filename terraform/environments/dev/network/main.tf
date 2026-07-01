provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Owner = "Prabhmeet"
    }
  }
}

variable "aws_region" {}
variable "env" {}
variable "cluster_name" {}
variable "kubernetes_version" {}

module "spoke_network" {
  source = "../../../modules/spoke-network"
  
  env                      = var.env
  aws_region               = var.aws_region
  
  frontend_vpc_cidr        = "10.12.0.0/16"
  frontend_private_subnets = ["10.12.1.0/24", "10.12.2.0/24", "10.12.3.0/24"]
  frontend_intra_subnets   = ["10.12.250.0/28", "10.12.250.16/28", "10.12.250.32/28"]
  
  backend_vpc_cidr         = "10.22.0.0/16"
  backend_private_subnets  = ["10.22.1.0/24", "10.22.2.0/24", "10.22.3.0/24"]
  backend_intra_subnets    = ["10.22.250.0/28", "10.22.250.16/28", "10.22.250.32/28"]
}

output "frontend_vpc_id" {
  value = module.spoke_network.frontend_vpc_id
}
output "backend_vpc_id" {
  value = module.spoke_network.backend_vpc_id
}

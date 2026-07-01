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

  frontend_vpc_cidr        = "10.11.0.0/16"
  frontend_private_subnets = ["10.11.1.0/24", "10.11.2.0/24","10.11.3.0/24"]
  frontend_intra_subnets   = ["10.11.4.0/28", "10.11.5.0/28","10.11.6.0/28"]

  backend_vpc_cidr         = "10.21.0.0/16"
  backend_private_subnets  = ["10.21.1.0/24", "10.21.2.0/24","10.21.3.0/24"]
  backend_intra_subnets    = ["10.21.4.0/28", "10.21.5.0/28","10.21.6.0/28"]

  tgw_destinations         = ["0.0.0.0/0", "192.178.0.0/16"]
}

output "frontend_vpc_id" {
  value = module.spoke_network.frontend_vpc_id
}
output "backend_vpc_id" {
  value = module.spoke_network.backend_vpc_id
}

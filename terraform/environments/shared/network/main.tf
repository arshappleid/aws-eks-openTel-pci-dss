provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { Owner = "Prabhmeet" }
  }
}

variable "aws_region" {}
variable "vpc_cidr" {}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

module "inspection_network" {
  source = "../../../modules/inspection-network"
  
  aws_region      = var.aws_region
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

output "vpc_id" {
  value = module.inspection_network.vpc_id
}
output "private_subnets" {
  value = module.inspection_network.private_subnets
}
output "public_subnets" {
  value = module.inspection_network.public_subnets
}

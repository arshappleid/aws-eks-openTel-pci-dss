terraform {
  backend "s3" {
    bucket = "prab-terraform-backend"
    key    = "eks-project/tfstate/stage/network/terraform.tfstate"
    region = "us-east-1"
  }
}
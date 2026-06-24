terraform {
  backend "s3" {
    bucket = "prab-terraform-backend"
    key    = "eks-project/tfstate/dev/network/terraform.tfstate"
    region = "us-east-1"
  }
}
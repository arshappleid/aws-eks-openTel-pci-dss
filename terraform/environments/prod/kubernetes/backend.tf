terraform {
  backend "s3" {
    bucket         = "prab-terraform-backend"
    key            = "eks-project/prod/kubernetes.tfstate"
    region         = "us-east-1"
  }
}

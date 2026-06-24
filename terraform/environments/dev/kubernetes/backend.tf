terraform {
  backend "s3" {
    bucket         = "prab-terraform-backend"
    key            = "eks-project/dev/kubernetes.tfstate"
    region         = "us-east-1"
  }
}
